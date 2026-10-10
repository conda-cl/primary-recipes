#!/bin/bash
set -euo pipefail

: "${PREFIX:?PREFIX not set}"
case "$PREFIX" in *'$'*) echo "bad PREFIX: $PREFIX" >&2; exit 1;; esac

export LISP=sbcl
export CLFLAGS="--non-interactive --no-sysinit --no-userinit"
export QL_TOPDIR="$PREFIX/quicklisp/"
export CLDIR="$PREFIX/common-lisp"
export CL_SOURCE_REGISTRY="$CLDIR//:"
mkdir -p "$QL_TOPDIR" "$CLDIR/ql-https"

mkdir -p "$QL_TOPDIR" "$CLDIR"

# Install ql-https itself from the already-checked-out, pinned source
# tree instead of letting install.sh re-clone (which would ignore
# the pinned rev above).
cp -r "$SRC_DIR"/. "$CLDIR/ql-https/"
rm -rf "$CLDIR/ql-https/.git"

echo "Downloading quicklisp metadata..."
mkdir -p "$QL_TOPDIR"
meta=$( curl -s https://beta.quicklisp.org/client/quicklisp.sexp | \
            awk '/:client-tar/,/)/' | tr '\n' ' ' | tr -s ' ' )

url=$( perl -nle 'print $& if m{(?<=:url ")[^"]*}g' <<< "$meta" )
[[ "$url" =~ ^http:// ]] && url="https${url#http}"
sha256=$( perl -nle 'print $& if m{(?<=:sha256 ")[^"]*}g' <<< "$meta" )

echo "Downloading quicklisp client..."
curl -s "$url" -o "$QL_TOPDIR"/quicklisp.tar

if [ "$sha256" != "$(openssl dgst -sha256 "$QL_TOPDIR"/quicklisp.tar  | cut -d' ' -f 2)" ]
then
    echo "sha mismatch" >&2
    exit 1
fi

tar xf "$QL_TOPDIR"/quicklisp.tar -C "$QL_TOPDIR"
rm "$QL_TOPDIR"/quicklisp.tar

# Instead of the clone here, we copy from above.
# echo "Cloning ql-https..."
# git clone https://github.com/rudolfochrist/ql-https "$CLDIR"/ql-https

echo "Running setup code..."
$LISP $CLFLAGS \
  --eval '(require :asdf)' \
  --load "$CLDIR/ql-https/ql-setup.lisp" \
  --eval '(setf ql-setup:*quicklisp-home*
                (uiop:ensure-directory-pathname (uiop:getenv "QL_TOPDIR")))' \
  --load "$CLDIR/ql-https/install.lisp"

cat > "$QL_TOPDIR/setup.lisp" <<'EOF'
(require 'asdf)
(let ((quicklisp-init
        (merge-pathnames "../common-lisp/ql-https/ql-setup.lisp"
                         (or *load-truename* *default-pathname-defaults*))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)
    (uiop:symbol-call :ql-setup :setup)))

#+ql-https
(setf ql-https:*quietly-use-https* t)
EOF

mkdir -p "$PREFIX/lib/sbcl/sbclrc.d/"
cat > "$PREFIX/lib/sbcl/sbclrc.d/10-quicklisp.lisp" <<'EOF'
(require 'asdf)

#-quicklisp
(let* ((quicklisp-home (merge-pathnames "quicklisp/"
                                       (uiop:ensure-directory-pathname
                                        (or (uiop:getenv "CONDA_PREFIX")
                                            (user-homedir-pathname)))))
       (quicklisp-init (merge-pathnames "setup.lisp" quicklisp-home)))
  (when (probe-file quicklisp-init)
    (load quicklisp-init))
  (setf (symbol-value (find-symbol "*QUICKLISP-HOME*" :ql)) quicklisp-home))

EOF

echo "All done!"
