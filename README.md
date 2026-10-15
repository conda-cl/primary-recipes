Recipes for prefix.dev Common Lisp channel
---

**Why**

You want one step project-local solution to

1. Installing Common Lisp implementation
2. Foreign Libraries
3. Common Lisp libraries
4. Manage lock files to ensure reproducible builds
5. In a cross-platform manner

**How**

This is accomplished by

1. `recipe.yaml` files in the respective [./recipes/](./recipes/) directory. It houses recipes for building packages with [rattler-build](https://rattler-build.prefix.dev/). There are various helper scripts in the current directory to generate and manage these recipes. Packages live at https://prefix.dev/channels/@common-lisp/common-lisp

2. Package manager clients such as [pixi](https://pixi.prefix.dev/latest/installation/) (recommended), but also `mamba`, `micromamba` and the contentious `conda`. `pixi` is an amazingly-improved version of conda with more features.

### Using pixi for your own project

First install [pixi](https://pixi.prefix.dev/latest/installation/). Then -

1. Create directory

        mkdir my-project && cd my-project

2. Start a pixi project. This should create a `pixi.`toml and `pixi.lock` file in the current directory. You can read more under the [Getting Started](https://pixi.prefix.dev/latest/first_workspace/) section of pixi.

        pixi init

3. Add common lisp prefix.dev channel

pixi workspace channel add --prepend https://prefix.dev/conda-forge https://prefix.dev/common-lisp/common-lisp


4. Install a common lisp implementation and some libraries

        pixi add sbcl alexandria cl-cffi

5. Run them

        pixi run sbcl --no-userinit

```
This is SBCL 2.6.9, an implementation of ANSI Common Lisp.
More information about SBCL is available at <http://www.sbcl.org/>.

SBCL is free software, provided as is, with absolutely no warranty.
It is mostly in the public domain; some portions are provided under
BSD-style licenses.  See the CREDITS and COPYING files in the
distribution for more information.
* (require 'asdf)
("ASDF" "asdf" "UIOP" "uiop")
* (asdf:load-system "alexandria")
T
*
```

ASDF is configured using `CL_SOURCE_REGISTRY` environment variable to look up projects under (i) current directory, and (ii) `common-lisp/` directory under the pixi env (see the `.pixi/` directory that gets generated). Thus, these are isolated from your global lisp workspace at `~/common-lisp/` etc.

You can also install quicklisp with `pixi add ql-https`. This will install quicklisp to the `.pixi` directory. You can then use quicklisp to install packages that are still absent from the prefix.dev/common-lisp channel. If you are using the latest SBCL, it should be configured to pick up the quicklisp configuration file from the respective `lib/sbcl/sbclrc.d` directory under `.pixi/`.

[isocline-repl](https://github.com/digikar99/cl-isocline/) is also available that supports multiline editing, syntax highlighting and basic autocompletion.

    pixi add cl-isocline-repl
    pixi run cl-isocline-repl



### Creating a recipe and adding packages to the channel

First get me a hold of the recipe, say, through a Pull Request. It's recommended you first test the recipe yourself.

A number of tools are provided in the form of bash scripts in the current directory:

1. generate-recipe-from-git.sh
2. build-test-recipe.sh
3. publish.sh
4. update-recipe.sh

Except the first one, all of them expect [rattler-build](https://rattler-build.prefix.dev/) to be globally installed.

    pixi global install rattler-build


After that, you can

    bash generate-recipe-from-git.sh <package-name> https://path/to/git/repo

This will create a `recipes/<package-name>/recipe.yaml`.

It is recommended that `<package-name>` should not conflict with existing packages in the conda ecosystem. To check this, perform a `pixi search <package-name>`. In case such a package already exists, you can prepend `cl-` to the package-name. For example, [cffi](https://cffi.readthedocs.io/en/stable/) and [asdf](https://www.asdf-format.org/projects/asdf/en/stable/) are already taken. Thus, we name the respective packages as `cl-cffi` and `cl-asdf`.

`generate-recipe-from-git.sh` also takes an optional third argument which can specify the git tag.

Once you have the basic skeleton of the recipe, you must fill in:

1. Its run and test dependencies.
2. License. For a list of licenses, see https://spdx.github.io/spdx-spec/v2.2.2/SPDX-license-list/
3. Documentation or Homepage.
4. One-line summary.
5. Short description.

After that, you can

    bash build-test-recipe.sh <package-name>

You can also test multiple ones at once with

    bash build-test-recipe.sh <package-name-1> <package-name-2> <package-name-3> ...

Version formats are mainly of two kinds:

- commit based: these correspond to the date of the latest commit in the form "0.0.0.YYYY.MM.DD"
- tag/version based: these correspond to the latest tag, usually in the form "MAJOR.MINOR.PATCH"

Once I have your recipe, I can publish the recipe using `publish.sh` or `cross-publish.sh`. For the moment, this process is manual. Once the number of packages eventualy grow, and we have better tools than the above helper scripts, this can be automated to a CI.

Existing recipes can be updated using:

    update-recipe.sh <package-name>

This more-or-less preserves the structure, but the version handling is still buggy.

### But I don't want to issue a PR every time I update my package!

If this repository caught your eye, and you want to get your package into [prefix.dev/common-lisp](https://prefix.dev/channels/@common-lisp/common-lisp), I have plans for *metarecipes*!

Essentially, you supply information about *how to obtain the recipe*. Perhaps you maintain it at your own repo, in which case I need the path to raw `recipe.yaml` at your repo. If the recipe has changed, I can then publish it to the channel. Again, this can be automated in the future.

Alternatively, if you maintain many packages, I can provide you a repository under the [conda-cl](https://github.com/conda-cl/) and periodically publish the recipes from there.


### What about existing package managers

With ql-https above, this should play nice with quicklisp (and ultralisp). However, we still need to get in qlot.

In principle, ocicl and clpm can be added too.

The main benefit of the current approach is for specifying and installing foreign libraries with your project. In the past, this step often had to be performed manually, making it difficult to install lisp libraries that use foreign libraries, despite the availability of quicklisp and other tools.


