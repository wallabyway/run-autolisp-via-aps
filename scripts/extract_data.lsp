;; Extract GIS data, text labels, and dimensions to CSV
(defun c:ExtractData ()
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq csv_path (strcat (getvar "DWGPREFIX") "extracted_data.csv"))
  (setq csv_file (open csv_path "w"))
  
  ;; Write CSV header
  (write-line "Type,Layer,X,Y,Z,Text,Additional_Data" csv_file)
  
  ;; Extract from modelspace
  (setq modelspace (vla-get-ModelSpace doc))
  (vlax-for obj modelspace
    (extract-object-data obj csv_file)
  )
  
  ;; Extract from paperspace
  (setq paperspace (vla-get-PaperSpace doc))
  (vlax-for obj paperspace
    (extract-object-data obj csv_file)
  )
  
  (close csv_file)
  (princ (strcat "\nData extracted to: " csv_path))
  (princ)
)

(defun extract-object-data (obj csv_file)
  (setq obj_type (vla-get-ObjectName obj))
  (setq layer (vla-get-Layer obj))
  
  (cond
    ;; Text objects
    ((= obj_type "AcDbText")
     (setq text (vla-get-TextString obj))
     (setq pos (vla-get-InsertionPoint obj))
     (write-line (strcat "TEXT," layer "," (rtos (car pos) 2 6) "," (rtos (cadr pos) 2 6) "," (rtos (caddr pos) 2 6) ",\"" text "\",") csv_file)
    )
    
    ;; MText objects
    ((= obj_type "AcDbMText")
     (setq text (vla-get-Contents obj))
     (setq pos (vla-get-InsertionPoint obj))
     (write-line (strcat "MTEXT," layer "," (rtos (car pos) 2 6) "," (rtos (cadr pos) 2 6) "," (rtos (caddr pos) 2 6) ",\"" text "\",") csv_file)
    )
    
    ;; Dimensions
    ((= obj_type "AcDbAlignedDimension")
     (setq text (vla-get-TextOverride obj))
     (setq pos (vla-get-TextPosition obj))
     (write-line (strcat "DIMENSION," layer "," (rtos (car pos) 2 6) "," (rtos (cadr pos) 2 6) "," (rtos (caddr pos) 2 6) ",\"" text "\",") csv_file)
    )
    
    ;; Points (potential GIS coordinates)
    ((= obj_type "AcDbPoint")
     (setq pos (vla-get-Coordinates obj))
     (write-line (strcat "POINT," layer "," (rtos (car pos) 2 6) "," (rtos (cadr pos) 2 6) "," (rtos (caddr pos) 2 6) ",,") csv_file)
    )
    
    ;; Lines (potential GIS features)
    ((= obj_type "AcDbLine")
     (setq start_pt (vla-get-StartPoint obj))
     (setq end_pt (vla-get-EndPoint obj))
     (write-line (strcat "LINE," layer "," (rtos (car start_pt) 2 6) "," (rtos (cadr start_pt) 2 6) "," (rtos (caddr start_pt) 2 6) ",START,") csv_file)
     (write-line (strcat "LINE," layer "," (rtos (car end_pt) 2 6) "," (rtos (cadr end_pt) 2 6) "," (rtos (caddr end_pt) 2 6) ",END,") csv_file)
    )
    
    ;; Polylines (potential GIS polygons)
    ((= obj_type "AcDbPolyline")
     (setq vertices (vla-get-Coordinates obj))
     (setq i 0)
     (repeat (/ (length vertices) 2)
       (setq x (nth i vertices))
       (setq y (nth (1+ i) vertices))
       (write-line (strcat "POLYLINE," layer "," (rtos x 2 6) "," (rtos y 2 6) ",0,VERTEX,") csv_file)
       (setq i (+ i 2))
     )
    )
  )
)

;; Execute the function
(c:ExtractData) 