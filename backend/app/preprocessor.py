import os
import cv2
import numpy as np
from PIL import Image
import math
from typing import Tuple, Dict, Any, Optional, List

ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.bmp', '.webp', '.tiff'}
MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024  # 25 MB

def validate_image_file(file_path: str) -> Tuple[bool, Optional[str]]:
    """Validate that the file exists, has a valid extension, reasonable size, and is readable."""
    if not os.path.exists(file_path):
        return False, "File does not exist."
    
    file_size = os.path.getsize(file_path)
    if file_size == 0:
        return False, "Image file is empty."
    if file_size > MAX_FILE_SIZE_BYTES:
        return False, f"File size ({file_size / (1024 * 1024):.1f} MB) exceeds maximum allowed size (25 MB)."
    
    ext = os.path.splitext(file_path)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        return False, f"Unsupported image format '{ext}'. Allowed formats: {', '.join(ALLOWED_EXTENSIONS)}"
    
    try:
        with Image.open(file_path) as img:
            img.verify()
    except Exception as e:
        return False, f"Image file is corrupted or unreadable: {str(e)}"
    
    return True, None


def analyze_image_quality(gray_img: np.ndarray) -> Dict[str, Any]:
    """
    Analyzes handwriting image quality for blur, lighting, contrast, and noise.
    Returns quality score (0.0 to 1.0) and helpful user guidance warnings.
    """
    warnings = []
    
    # 1. Blur Detection (Laplacian Variance)
    laplacian_var = float(cv2.Laplacian(gray_img, cv2.CV_64F).var())
    if laplacian_var < 50.0:
        warnings.append("Image appears significantly blurry. Keep your device steady for clearer handwriting recognition.")
    elif laplacian_var < 85.0:
        warnings.append("Slight motion blur detected. Handwriting recognition may be degraded.")

    # 2. Lighting & Brightness Analysis
    mean_val = float(np.mean(gray_img))
    if mean_val < 65.0:
        warnings.append("Image is quite dark. Try taking the photo in brighter lighting or using flash.")
    elif mean_val > 225.0:
        warnings.append("Image is washed out or overexposed. Try adjusting lighting or reducing glare.")

    # 3. Contrast Analysis
    std_val = float(np.std(gray_img))
    if std_val < 32.0:
        warnings.append("Low contrast between ink and background. Darker ink or flatter paper will improve results.")

    # 4. Ink Density Check
    _, otsu = cv2.threshold(gray_img, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    ink_ratio = float(np.sum(otsu == 255) / (gray_img.shape[0] * gray_img.shape[1]))
    if ink_ratio < 0.005:
        warnings.append("Very little handwriting or ink detected on the page.")

    # Compute composite quality score
    blur_score = min(1.0, laplacian_var / 300.0)
    contrast_score = min(1.0, std_val / 65.0)
    lighting_score = 1.0 - (abs(mean_val - 145.0) / 145.0)
    lighting_score = max(0.0, min(1.0, lighting_score))
    
    overall_quality = round(0.45 * blur_score + 0.35 * contrast_score + 0.20 * lighting_score, 2)
    overall_quality = max(0.1, min(1.0, overall_quality))

    return {
        "quality_score": overall_quality,
        "laplacian_variance": round(laplacian_var, 1),
        "mean_brightness": round(mean_val, 1),
        "contrast_std": round(std_val, 1),
        "ink_ratio": round(ink_ratio, 4),
        "warnings": warnings
    }


def normalize_illumination(gray_img: np.ndarray) -> np.ndarray:
    """
    Normalizes uneven lighting across pages using gentle division normalization.
    Preserves fine handwriting strokes and avoids blotches or halo artifacts.
    """
    try:
        h, w = gray_img.shape[:2]
        # Check if lighting is actually uneven across quadrants
        quads = [
            gray_img[:h//2, :w//2],
            gray_img[:h//2, w//2:],
            gray_img[h//2:, :w//2],
            gray_img[h//2:, w//2:]
        ]
        means = [float(np.mean(q)) for q in quads]
        # If lighting variation across page is low, leave natural illumination intact
        if (max(means) - min(means)) < 26.0:
            return gray_img

        # Large Gaussian kernel for smooth background illumination estimate
        kernel_size = max(51, (min(h, w) // 10) | 1)
        bg = cv2.GaussianBlur(gray_img, (kernel_size, kernel_size), 0)
        bg = np.maximum(bg.astype(np.float32), 1.0)
        
        # Division normalization scaled to bright paper background
        norm = np.clip((gray_img.astype(np.float32) / bg) * 235.0, 0, 255).astype(np.uint8)
        return norm
    except Exception:
        return gray_img


def soft_attenuate_notebook_lines(gray_img: np.ndarray) -> Tuple[np.ndarray, bool]:
    """
    Detects notebook horizontal ruled lines and softly attenuates them.
    CRITICAL: Does NOT use inpainting or stroke erosion. Preserves all apostrophes,
    commas, dots of 'i', and descenders (g, y, j, p, q).
    """
    try:
        h, w = gray_img.shape[:2]
        thresh = cv2.adaptiveThreshold(
            gray_img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 25, 12
        )

        # Look strictly for wide horizontal lines (at least 20% of page width)
        line_len = max(35, w // 25)
        horiz_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (line_len, 1))
        horiz_lines = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, horiz_kernel)

        # Detect vertical/diagonal handwriting strokes
        vert_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, 9))
        vert_strokes = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, vert_kernel)
        vert_strokes_dilated = cv2.dilate(vert_strokes, np.ones((3, 3), np.uint8), iterations=1)

        # Only isolate pure horizontal lines away from handwriting strokes
        pure_lines = cv2.subtract(horiz_lines, vert_strokes_dilated)
        line_pixels = int(np.sum(pure_lines == 255))
        total_pixels = h * w

        if (line_pixels / total_pixels) > 0.003:
            # Soft lightening: reduce darkness of ruled line pixels by 30% without deleting
            mask = pure_lines > 0
            attenuated = gray_img.copy()
            attenuated[mask] = np.clip(attenuated[mask].astype(np.int16) + 40, 0, 255).astype(np.uint8)
            return attenuated, True

        return gray_img, False
    except Exception:
        return gray_img, False


def compute_skew_angle(cv_img: np.ndarray) -> float:
    """
    Conservatively detects genuine page rotation/skew using long edge lines.
    Avoids mistaking slanted handwriting strokes or random letters for page skew.
    """
    try:
        h, w = cv_img.shape[:2]
        if len(cv_img.shape) == 3:
            gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
        else:
            gray = cv_img.copy()
            
        edges = cv2.Canny(gray, 60, 180, apertureSize=3)
        # Require lines to span at least 30% of image width to represent true paper/margin lines
        min_line_len = max(80, int(w * 0.30))
        lines = cv2.HoughLinesP(edges, 1, np.pi / 180, 120, minLineLength=min_line_len, maxLineGap=15)
        
        if lines is None or len(lines) < 3:
            return 0.0
            
        angles = []
        for line in lines:
            x1, y1, x2, y2 = line[0]
            if x2 - x1 == 0:
                continue
            angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
            # Focus on near horizontal lines (-20 to 20 deg)
            if -20.0 <= angle <= 20.0:
                angles.append(angle)
                
        # Require at least 3 consistent lines with low angle variance
        if len(angles) < 3:
            return 0.0
            
        std_angle = float(np.std(angles))
        if std_angle > 1.2:
            # High variance means lines are random handwriting slants, not a tilted page
            return 0.0
            
        median_angle = float(np.median(angles))
        if abs(median_angle) < 0.8:
            return 0.0
            
        return median_angle
    except Exception:
        return 0.0


def rotate_image(cv_img: np.ndarray, angle: float) -> np.ndarray:
    """
    Rotates image by given angle with clean white constant borders.
    CRITICAL: Never uses BORDER_REPLICATE to avoid vertical/horizontal edge streaks.
    """
    if abs(angle) < 0.4:
        return cv_img
        
    (h, w) = cv_img.shape[:2]
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)
    
    cos = np.abs(M[0, 0])
    sin = np.abs(M[0, 1])
    new_w = int((h * sin) + (w * cos))
    new_h = int((h * cos) + (w * sin))
    
    M[0, 2] += (new_w / 2) - center[0]
    M[1, 2] += (new_h / 2) - center[1]
    
    # White border constant prevents black borders and edge streaking
    border_val = (255, 255, 255) if len(cv_img.shape) == 3 else 255
    rotated = cv2.warpAffine(
        cv_img,
        M,
        (new_w, new_h),
        flags=cv2.INTER_CUBIC,
        borderMode=cv2.BORDER_CONSTANT,
        borderValue=border_val
    )
    return rotated


def preprocess_handwriting_image(
    input_path: str,
    output_path: str,
    enhance_contrast: bool = True,
    denoise: bool = True,
    binarize: bool = False,
    deskew: bool = True,
    attenuate_lines: bool = False,
    remove_shadows: bool = True
) -> Dict[str, Any]:
    """
    Applies non-destructive image preprocessing for messy handwriting OCR recognition.
    Guarantees:
    - Never distorts page geometry or adds border artifacts (no BORDER_REPLICATE).
    - Preserves delicate handwriting strokes, dots of 'i', and apostrophes.
    - Preserves the original image file intact.
    - Generates clean, crisp processed representation and high-contrast binary fallback.
    """
    img = cv2.imread(input_path)
    if img is None:
        raise ValueError("Could not read image with OpenCV")
        
    orig_h, orig_w = img.shape[:2]
    applied_operations = []
    
    # 1. Conservative scaling: Only upscale if image resolution is very small (< 500px)
    # Downscale only if excessively large (> 2800px)
    max_dim = max(orig_h, orig_w)
    min_dim = min(orig_h, orig_w)
    
    scale_factor = 1.0
    if min_dim < 500:
        scale_factor = 600.0 / min_dim
    elif max_dim > 1536:
        scale_factor = 1440.0 / max_dim
        
    if scale_factor != 1.0:
        target_w = int(orig_w * scale_factor)
        target_h = int(orig_h * scale_factor)
        img = cv2.resize(
            img,
            (target_w, target_h),
            interpolation=cv2.INTER_CUBIC if scale_factor > 1.0 else cv2.INTER_AREA
        )
        applied_operations.append(f"scale ({orig_w}x{orig_h} -> {target_w}x{target_h})")

    # 2. Conservative deskew (only if consistent page tilt detected)
    detected_angle = 0.0
    if deskew:
        detected_angle = compute_skew_angle(img)
        if abs(detected_angle) >= 0.8 and abs(detected_angle) <= 25.0:
            img = rotate_image(img, detected_angle)
            applied_operations.append(f"deskew ({detected_angle:.1f}°)")
            
    # 3. Grayscale conversion
    if len(img.shape) == 3:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    else:
        gray = img.copy()
    applied_operations.append("grayscale")
    
    # 4. Image Quality Analysis
    quality_analysis = analyze_image_quality(gray)

    # 5. Illumination normalization (gentle division, no blotches)
    if remove_shadows:
        gray = normalize_illumination(gray)
        applied_operations.append("smooth illumination normalization")

    # 6. Ruled line soft attenuation (non-destructive)
    if attenuate_lines:
        gray, lines_found = soft_attenuate_notebook_lines(gray)
        if lines_found:
            applied_operations.append("notebook line attenuation")

    # 7. Contrast enhancement (Gentle CLAHE - clipLimit 1.6 preserves faint ink without blowout)
    if enhance_contrast:
        clahe = cv2.createCLAHE(clipLimit=1.6, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)
        applied_operations.append("contrast enhancement (CLAHE)")
    else:
        enhanced = gray
        
    # 8. Edge-preserving gentle bilateral filter
    if denoise:
        denoised = cv2.bilateralFilter(enhanced, d=5, sigmaColor=30, sigmaSpace=30)
        applied_operations.append("bilateral noise smoothing")
    else:
        denoised = enhanced
        
    # 9. Primary output image
    if binarize:
        _, binary = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        final_img = binary
        applied_operations.append("adaptive binarization")
    else:
        final_img = denoised
        
    cv2.imwrite(output_path, final_img)

    # 10. Secondary fallback binary representation
    bin_output_path = output_path.replace(".png", "_bin.png")
    _, bin_img = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    cv2.imwrite(bin_output_path, bin_img)
    
    return {
        "original_dimensions": {"width": orig_w, "height": orig_h},
        "processed_dimensions": {"width": final_img.shape[1], "height": final_img.shape[0]},
        "detected_skew_angle": detected_angle,
        "operations": applied_operations,
        "processed_path": output_path,
        "binary_path": bin_output_path,
        "quality_analysis": quality_analysis
    }
