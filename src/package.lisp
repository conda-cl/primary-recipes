(cl:defpackage :rattler-recipe-manager
  (:use :cl :let-plus)
  (:export #:update-recipe))

(in-package :rattler-recipe-manager)

(defvar *quiet* nil)

(defun qformat (destination control-string &rest format-arguments)
  (unless *quiet*
    (apply #'format destination control-string format-arguments)))

(defun recipe-path (recipe-designator)
  (merge-pathnames (pathname
                    (format nil "recipes/~A/recipe.yaml"
                            (string-downcase recipe-designator)))
                   (asdf:system-source-directory "rattler-recipe-manager")))

(defun version-kind (version)
  (case (count #\. version)
    (5
     (if (uiop:string-prefix-p "0.0.0" version)
         :latest-tag-commit
         :latest-commit))
    (t
     :latest-tag)))

(defun recipe-lines-match (lines regex)
  (loop :for line :in lines
        :for line-number :from 0
        :do (multiple-value-bind (match-start match-end reg-start reg-end)
                (ppcre:scan regex line)
              (declare (ignore match-end))
              (when match-start
                (assert (= 1 (length reg-start)))
                (return-from recipe-lines-match
                  (values (subseq line (elt reg-start 0) (elt reg-end 0))
                          line-number))))))

(defun recipe-version (lines)
  (recipe-lines-match lines "\\s+version: (.*)$"))

(defun recipe-url (lines)
  (recipe-lines-match lines "git: (.*)$"))

(defmethod latest-rev (repo-url (version-kind (eql :latest-commit)))
  (loop :for line :in (uiop:split-string
                       (uiop:run-program (list "git" "ls-remote" "-q" repo-url)
                                         :output :string
                                         :error-output *error-output*)
                       :separator '(#\newline #\return))
        :do (destructuring-bind (commit ref)
                (uiop:split-string line :separator '(#\tab))
              (when (string= ref "HEAD")
                (return-from latest-rev commit)))))

(defun ref-tag (ref)
  (cond ((uiop:string-prefix-p "refs/tags/v" ref)
         (subseq ref (length "refs/tags/v")))
        ((uiop:string-prefix-p "refs/tags/" ref)
         (subseq ref (length "refs/tags/")))))

(defun ref-tagged-p (ref)
  (uiop:parse-version (ref-tag ref)))

(defmethod latest-rev (repo-url (version-kind (eql :latest-tag)))
  (let+ ((lines (uiop:split-string
                 (uiop:run-program (list "git" "ls-remote" "-q"
                                         "--sort=-v:refname"
                                         repo-url)
                                   :output :string
                                   :error-output *error-output*)
                 :separator '(#\newline #\return)))
         (split (mapcar (lambda (line)
                          (uiop:split-string line :separator '(#\tab)))
                        lines))
         (tagged (loop :for (commit ref) :in split
                       :for tag := (ref-tag ref)
                       :for version := (uiop:parse-version tag)
                       :when version
                         :collect (list commit tag)))
         ((commit tag) (first
                        (print
                         (nreverse
                          (sort tagged #'uiop:version< :key #'second))))))
    (values commit
            (format nil "\"~A\"" tag))))

(defun replace-rev (line latest-rev)
  (multiple-value-bind (match-start match-end reg-start reg-end)
      (ppcre:scan "rev: (.*)$" line)
    (declare (ignore match-end reg-end))
    (when match-start
      (assert (= 1 (length reg-start)))
      (concatenate 'string
                   (subseq line 0 (elt reg-start 0))
                   latest-rev))))

(defun ensure-latest-version (latest-version repo-url)
  (when latest-version (return-from ensure-latest-version latest-version))
  (let ((version))
    (uiop:with-current-directory (#p"/tmp/")
      (uiop:run-program (list "git" "clone" "--depth" "1" repo-url "tmpgit"))
      (uiop:with-current-directory ((merge-pathnames "tmpgit"))
        (setf version
              (format nil "\"0.0.0.~A\""
                      (uiop:stripln
                       (uiop:run-program "git log -1 --date=format:%Y.%m.%d --format=%cd"
                                         :output :string)))))
      (uiop:run-program "rm -rf tmpgit"))
    version))

(defun replace-version (line latest-version repo-url)
  (setf latest-version (ensure-latest-version latest-version repo-url))
  (multiple-value-bind (match-start match-end reg-start reg-end)
      (ppcre:scan "version: (.*)$" line)
    (declare (ignore match-end reg-end))
    (when match-start
      (assert (= 1 (length reg-start)))
      (concatenate 'string
                   (subseq line 0 (elt reg-start 0))
                   latest-version))))

(defun update-rev (lines)
  (let+ (((&values version version-line-number) (recipe-version lines))
         (version-kind                          (version-kind version))
         ((&values current-rev rev-line-number) (recipe-lines-match lines "rev: (.*)$"))

         (repo-url                              (recipe-lines-match lines "git: (.*)"))
         ((&values latest-rev latest-version) (when repo-url
                                                (latest-rev repo-url version-kind))))
    (if (not repo-url)
        (qformat t "  No repo url found.")
        (if (string/= current-rev latest-rev)
            (progn
              (qformat t "  Updating~%    from ~A~%      to ~A~%"
                       current-rev
                       latest-rev)
              (setf (nth version-line-number lines)
                    (replace-version (nth version-line-number lines)
                                     latest-version
                                     repo-url))
              (setf (nth rev-line-number lines)
                    (replace-rev (nth rev-line-number lines)
                                 latest-rev)))
            (qformat t "  It is up-to-date at ~A.~%" latest-rev)))))

(defun update-recipe (name &optional quiet)
  (unless quiet (format t "Checking ~A...~%" name))
  (force-output)
  (let* ((*quiet* quiet)
         (path (recipe-path name))
         (recipe (alexandria:read-file-into-string path))
         (lines (uiop:split-string recipe :separator '(#\newline #\return))))
    (when (update-rev lines)
      (alexandria:write-string-into-file
       (format nil "~{~A~^~%~}" lines)
       path
       :if-exists :supersede))))
