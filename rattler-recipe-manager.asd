(asdf:defsystem "rattler-recipe-manager"
  :depends-on ("alexandria"
               "cl-ppcre"
               "let-plus")
  :pathname #p"src/"
  :components ((:file "package")))
