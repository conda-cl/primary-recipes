Recipes for prefix.dev Common Lisp channel
---

> **Disclaimer:** This project uses code generated using Claude, in
>
> - generate-recipe-from-git.sh
> - test-recipe-and-publish.sh
> - update-recipe.sh
>
> However, this has been checked, modified and adapted by me. I hope anyone familiar with bash can go over it in a matter of a minute or few.

Channel at: https://prefix.dev/channels/@common-lisp/common-lisp

Installation: https://pixi.prefix.dev/latest/installation/

Add package: 

    pixi workspace channel add --prepend https://prefix.dev/conda-forge https://prefix.dev/common-lisp/common-lisp

Install:

    pixi add <package-name>


### Adding more recipes

Recipe can be generated using

    ./generate-recipe-from-git.sh <package-name-for-prefix.dev> <repo-url> [ref]

Once generated, fill in the "about" section, and issue a PR.

License list: https://spdx.github.io/spdx-spec/v2.2.2/SPDX-license-list/

Version formats are mainly of two kinds:

- commit based: these correspond to the date of the latest commit in the form "0.0.0.YYYY.MM.DD"
- tag/version based: these correspond to the latest tag, usually in the form "MAJOR.MINOR.PATCH"

### Updating recipes

    update-recipe.sh <package-name-for-prefix.dev>

