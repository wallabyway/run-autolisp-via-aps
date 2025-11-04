;; AutoLISP script to export geolocation data from Civil 3D drawing
;; This script extracts GeoLocationData and saves it to a JSON file
;; Equivalent to the C# EXPORTGEO command in convert.cs

(defun c:ExportGeo ()
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq db (vla-get-Database doc))
  
  (princ "\nExtracting geolocation data...")
  
  ;; Try to get the GeoData object
  (setq geodata_id (vla-get-GeoDataObject db))
  
  (if (and geodata_id (not (vlax-object-null-p geodata_id)))
    (progn
      ;; Get the GeoLocationData object
      (setq geodata (vlax-ename->vla-object geodata_id))
      
      ;; Extract geolocation properties
      (setq coord_system (vla-get-CoordinateSystem geodata))
      (setq design_pt (vla-get-DesignPoint geodata))
      (setq ref_pt (vla-get-ReferencePoint geodata))
      (setq north_vec (vla-get-NorthDirection geodata))
      (setq vert_scale (vla-get-VerticalUnitScale geodata))
      (setq horiz_scale (vla-get-HorizontalUnitScale geodata))
      
      ;; Get GeoRSS tag if available
      (setq georss_tag "")
      (if (vlax-property-available-p geodata 'GeoRSSTag)
        (setq georss_tag (vla-get-GeoRSSTag geodata))
      )
      
      ;; Calculate north direction angle
      ;; Convert vector to angle in degrees
      (setq north_angle (* (/ 180.0 pi) (atan (vlax-safearray-get-element north_vec 1) 
                                               (vlax-safearray-get-element north_vec 0))))
      
      ;; Extract coordinate values
      (setq design_x (vlax-safearray-get-element design_pt 0))
      (setq design_y (vlax-safearray-get-element design_pt 1))
      (setq design_z (vlax-safearray-get-element design_pt 2))
      
      (setq ref_x (vlax-safearray-get-element ref_pt 0))
      (setq ref_y (vlax-safearray-get-element ref_pt 1))
      (setq ref_z (vlax-safearray-get-element ref_pt 2))
      
      ;; Build JSON string
      (setq json_str "{\n")
      (setq json_str (strcat json_str "  \"GeoRSSTag\": \"" (if georss_tag georss_tag "") "\",\n"))
      (setq json_str (strcat json_str "  \"CoordinateSystem\": \"" coord_system "\",\n"))
      (setq json_str (strcat json_str "  \"NorthDirectionVectorAngle\": " (rtos north_angle 2 6) ",\n"))
      (setq json_str (strcat json_str "  \"X\": " (rtos design_x 2 6) ",\n"))
      (setq json_str (strcat json_str "  \"Y\": " (rtos design_y 2 6) ",\n"))
      (setq json_str (strcat json_str "  \"Z\": " (rtos design_z 2 6) ",\n"))
      (setq json_str (strcat json_str "  \"VerticalUnitsScale\": " (rtos vert_scale 2 6) ",\n"))
      (setq json_str (strcat json_str "  \"HorizontalUnitsScale\": " (rtos horiz_scale 2 6) ",\n"))
      (setq json_str (strcat json_str "  \"ReferencePoint\": {\n"))
      (setq json_str (strcat json_str "    \"X\": " (rtos ref_x 2 6) ",\n"))
      (setq json_str (strcat json_str "    \"Y\": " (rtos ref_y 2 6) ",\n"))
      (setq json_str (strcat json_str "    \"Z\": " (rtos ref_z 2 6) "\n"))
      (setq json_str (strcat json_str "  }\n"))
      (setq json_str (strcat json_str "}\n"))
      
      ;; Save to JSON file
      (setq json_path (strcat (getvar "DWGPREFIX") "geoData.json"))
      (setq json_file (open json_path "w"))
      (write-line json_str json_file)
      (close json_file)
      
      ;; Print success message
      (princ (strcat "\nGeolocation data exported successfully to: " json_path))
      (princ "\n\nGeolocation Data:")
      (princ (strcat "\n  Coordinate System: " coord_system))
      (princ (strcat "\n  Design Point: X=" (rtos design_x 2 2) ", Y=" (rtos design_y 2 2) ", Z=" (rtos design_z 2 2)))
      (princ (strcat "\n  Reference Point: X=" (rtos ref_x 2 2) ", Y=" (rtos ref_y 2 2) ", Z=" (rtos ref_z 2 2)))
      (princ (strcat "\n  North Angle: " (rtos north_angle 2 2) " degrees"))
      (princ (strcat "\n  Horizontal Scale: " (rtos horiz_scale 2 6)))
      (princ (strcat "\n  Vertical Scale: " (rtos vert_scale 2 6)))
    )
    (progn
      ;; No geolocation data found
      (princ "\nError: No geolocation data found in this drawing.")
      (princ "\nPlease ensure the drawing has been geolocated using the GEOGRAPHICLOCATION command.")
    )
  )
  
  (princ)
)

;; Execute the function
(c:ExportGeo)

