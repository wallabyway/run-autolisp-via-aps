;; AutoLISP script to modify title block and save as PDF
;; This script finds text objects containing "TITLE" and changes them to "HELLO WORLD"
;; Then saves the drawing as a PDF file

(defun c:ModifyTitleBlock ()
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq modelspace (vla-get-ModelSpace doc))
  
  ;; Find and modify title block text
  (vlax-for obj modelspace
    (if (= (vla-get-ObjectName obj) "AcDbText")
      (progn
        (setq text (vla-get-TextString obj))
        ;; Check if text contains "TITLE" (case insensitive)
        (if (wcmatch (strcase text) "*TITLE*")
          (progn
            (vla-put-TextString obj "HELLO WORLD")
            (princ (strcat "\nModified text: " text " -> HELLO WORLD"))
          )
        )
      )
    )
  )
  
  ;; Also check paperspace for title block text
  (setq paperspace (vla-get-PaperSpace doc))
  (vlax-for obj paperspace
    (if (= (vla-get-ObjectName obj) "AcDbText")
      (progn
        (setq text (vla-get-TextString obj))
        ;; Check if text contains "TITLE" (case insensitive)
        (if (wcmatch (strcase text) "*TITLE*")
          (progn
            (vla-put-TextString obj "HELLO WORLD")
            (princ (strcat "\nModified text: " text " -> HELLO WORLD"))
          )
        )
      )
    )
  )
  
  ;; Save as PDF
  (setq pdf_path (strcat (getvar "DWGPREFIX") "output.pdf"))
  (princ (strcat "\nSaving PDF to: " pdf_path))
  
  ;; Use PLOT command to save as PDF
  (command "._PLOT" 
           "Y"           ;; Plot to file
           ""            ;; Enter (use current layout)
           "DWG To PDF.pc3"  ;; Plotter configuration
           "ISO A4 (297.00 x 210.00 MM)"  ;; Paper size
           "M"           ;; Millimeters
           "L"           ;; Landscape
           "N"           ;; No plot offset
           "W"           ;; Window
           "0,0"         ;; First corner
           "297,210"     ;; Other corner
           "1=1"         ;; Plot scale
           "M"           ;; Plot scale units
           "Y"           ;; Plot with plot styles
           "Y"           ;; Plot lineweights
           "N"           ;; Don't plot transparency
           "Y"           ;; Plot paper space last
           "N"           ;; Don't hide paperspace objects
           "N"           ;; Don't plot with lineweights
           "N"           ;; Don't plot with plot styles
           pdf_path      ;; Output file name
           "N"           ;; Don't save changes to layout
           "Y"           ;; Yes to continue
  )
  
  (princ "\nTitle block modified and PDF saved successfully.")
  (princ)
)

;; Execute the function
(c:ModifyTitleBlock) 