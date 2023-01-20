+++
title = "Nix'ing Docker"
date = 2022-08-06
draft = false
+++

Since its Insider release debut, VS Code's _Remote Development Extension Pack_ (RDEP) has been a significant part of my workflow. It made reproducing my environments, tools, and services, a simple _"Reopen Folder in Container..."_ away. Though its simplicity comes at a cost. RDEP relies on proprietary tools for its workflow, the underlying container technologies are fairly complex, and VMs are required for platforms other than Linux. This is where I found Nix could help. 

<!-- more -->

# Introduction

[_Don't bore us, get to the "saurus"_](https://github.com/kalebpace/nix-flake-rust-nightly-vscode)
<sub>[_obscure joke found here_](https://www.youtube.com/watch?v=eQV95ehUU4s)</sub>

First, if you're new here (it's ok, I am too), welcome! Today's aim is to explore the potential benefits of Nix as a platform-agnostic dependency and environment manager. This is in direct contrast to containerized development workflows enabled by tools like the [_Remote Development Extension Pack_](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) (RDEP). The inspiration is drawn from a few key goals: reducing reliance on workflows only possible through proprietary tools such as RDEP, the performance impacts of cross-platform container development, and the difficulty in building reproducible environments without shipping image layers.

The article is by no means a comprehensive overview of the technologies used or their trade-offs. It will mostly discuss the ergonomics of these tools and occasionally try to justify why one tool may achieve a workflow more easily than the other. RDEP has primarily been a way to build project specific file systems, document tools, and track configurations used during development or deployment; so Nix solicited exploring it as a suitable alternative.  

# First Impressions

[The Nix promise is strong](https://nixos.org/guides/how-nix-works.html): managed reproducible build environments, cross-platform portability, and a complete dependency graph, all configured by a functional language. But as a cohesive project, it's a bit confusing at first. Nix Expressions, the term for any implemented Nix syntax, are ambiguous in trying to differentiate between NixOS and non-NixOS specific syntax. It's not immediately apparent where the line is drawn for NixOS, Nix configurations, Nix the package manager, and Nix the language. On top of this, to fully grasp a concept or find an answer, one must search _nixos.com_, _nixos.wiki_, and _nixos.com/manual_; each containing necessary bits of information. This is even apparent in the installation steps: 
- where the [download page](https://nixos.org/download.html) lists the installation command
- [the manual](https://nixos.org/manual/nix/stable/installation/multi-user.html) has steps to set up and secure the daemon as well as the build users
- and the [Nix Installation Guide](https://nixos.wiki/wiki/Nix_Installation_Guide) notes further methods including rootless configuration and how to determine your store location (both are fairly important use cases). 

It is recommended to install Nix in multi-user mode which happens to yield the most "docker-like" experience (e.g. user dispatches actions to daemon; build artifacts are shared between users). A rootless installation was attempted, but errors with the store path not-so-briefly hosed the entire Nix setup. It was frustrating to find the root cause, as there were no clear errors in terminal, even with verbosity on 5. Searching the error did not yield much. Neither the `#trivial` default Flake template (discussed in the next section) or `#compat` template could be initialized due to Nix referencing a deleted store path. Since it was behaving like a misconfiguration, a number of fixes were attempted to repair the store, including full reinstallation of Nix. Only when replicating the behavior as a new user, and finding no issue, that it narrowed down to a caching issue and not nix-daemon misconfiguration. The solution was to delete the `.cache/nix` directory in `$HOME`, but little information was found on how to manage this cache less destructively. Several hours were wasted comparing installation types and recovering from those attempts.

Frustrations aside, there does seem to be a very active community who praise the effortless maintenance Nix enables. Many have gone to replace VM and container workflows, with much satisfaction, after the initial learning curve. But the tumultuous introduction to the ecosystem left mixed feelings when justifying whether it was worth further effort.

# Setup

The first resource to dimly light any idea-bulbs, [authored by Xe](https://xeiaso.net/blog/how-i-start-nix-2020-03-08), explained preferred methods of starting Nix-based projects. However, [Flakes](https://xeiaso.net/blog/nix-flakes-1-2022-02-21) were introduced shortly after. Flakes are the now preferred way of managing projects and seem to be in direct conflict with [Lorri](https://github.com/nix-community/lorri) and [Niv](https://github.com/nmattia/niv). This analogy given by Xe helped tremendously in grokking how others used Nix and how it relates to projects it intends to replace: Flakes are to `docker-compose` as `default.nix` files are Dockerfiles. 

After a bit more reading, and the addition of [recommended VS Codium extensions](https://open-vsx.org/extension/bbenoist/Nix), initializing a Flake-based project is simple:
```bash
    # any arbitrary project directory
    $ cd ./workspace

    # will create a generic flake.nix 
    $ nix flake init --template templates#trivial

    # will create default.nix and shell.nix for compatability with flakes
    # and vscode extensions
    $ nix flake init --template templates#compat 

    # tell direnv to use flake environment by default
    $ echo 'use flake' > .envrc
```

# Usage

Take a moment to skim this Flake which configures a Rust environment with the nightly toolchain:
```nix
# flake.nix
{
  # Define your default inputs. These inputs could be overriden by 
  # other users when using this flake to customize it to their needs
  # (which is out of scope for this template)
  inputs = {
    # I tend to prefer unstable channels as its easier to find 
    # github issues when things break
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # flake-utils helps us remove cross-platform boilerplate
    utils.url = "github:numtide/flake-utils";

    # Provides a nix 'overlay' with the nightly rust toolchain.
    # Per the project's description, it aims to replace rustup usage
    # in flake-based projects. Also ships with rust-analyzer-nightly
    fenix.url = "github:nix-community/fenix";
  };

  outputs = { self, nixpkgs, utils, fenix }:

    # Define a system environment for your machine (e.g. system.x86_64-linux)
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { 
          # Inherit our current system environment configuration so nixpkgs
          # will fetch proper architectures, etc. 
          inherit system;

          # Apply the rust overlay which overrides any packages of 
          #the same name found in nixpkgs 
          overlays = [ fenix.overlay ];
        };

        # Define our desired toolchain based off a standard rust toolchain 
        # file. You could define the same components inside here, but 
        # rust-toolchain.toml is better documented, so it makes more sense.
        rust-toolchain = pkgs.fenix.fromToolchainFile {
          file = ./rust-toolchain.toml;

          # I cheated and used a dummy SHA to cause a conflict, where 
          # I then copied the conflicting SHA here to resolve the error. 
          # Unsure how to find the SHA "properly".  
          sha256 = "i2rzMf9nu5PXlOUk3LXBCVMRiTZDzlDW3x47/GPqAgw=";
        };
      in rec {

        # This is like starting a shell in a dev container.
        #
        # Define the shell we want to drop into when VSCodium loads or
        # 'nix develop' is run. 
        # 
        # 'with pkgs' scopes the following statement with that namespace,
        # so we don't need to type 'pkgs.rust-analyzer-nightly' and instead
        # directly reference it.
        devShell = with pkgs; mkShell {
          buildInputs = [
            rust-toolchain
            rust-analyzer-nightly
          ];
        };
      }
    );
}
```

This is a deceptively simple config. [<u>Many</u>](https://nixos.wiki/wiki/Rust) [<u>many</u>](https://github.com/nix-community/fenix) [<u>examples</u>](https://www.tomhoule.com/2021/building-rust-wasm-with-nix-flakes/) (including the [Language Reference](https://nixos.wiki/wiki/Overview_of_the_Nix_Language)) were needed to understand how overlays are leveraged to install nightly toolchain components. Two options between competing overlays exist: [_fenix_](https://github.com/nix-community/fenix) and [_rust-overlay_](https://github.com/oxalica/rust-overlay). With no clear ergonomic or optimal difference, _fenix_ was chosen, as _rust-analyzer-nightly_ is a nice-to-have and included by default.

After deciding to use a `rust-toolchain.toml`, and many failures to include the toolchain properly, it was discovered that new files must be tracked by git for Nix to copy it into the environment. There is really nothing in the tooling that indicates this behavior. It's possible that `Warning: the git workspace is dirty` intended to give an inclination towards this. But it was only after reading a few comments from community members saying "be sure to track your files, so they are copied to the store!", that the error had any meaning. After a few more tears, `rust-toolchain.toml` was no longer `No such file or directory`.

Writing and iterating on the flake is a bit tedious. There's no real intellisense for VS Codium yet, which impacts discoverability by a fair margin. The `nix repl` command is available, but requires reloading your flake into scope each time you make changes to discover properties available on your variables. The auto-formatter in the Nix IDE extension is also annoying. If a symbol is missed, it will remove white space and combine lines. No prior red-underlining or indication of error, it just leaves a mess to clean up.

Setting up rust-analyzer also presents a little challenge. The extension tries to find the server by the `RUST_SRC` location, but since each Nix package is in its own store path, the rust-analyzer server binary is not next to the expected location. The path to the server must be manually set in `.vscode/settings.json` after the environment is built. This setting need to be performed by any new user setting up the project since the path is unique.

# Comparison

All troubles aside, Nix cleans up extremely well.

#### "_Reopen Folder in Container..._"
With a properly configured `.envrc` and authorized [direnv](https://direnv.net/) (which also has a [zsh plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/direnv)), VS Codium can recognize all environment modifications made in the current shell; much like _"Reopen Folder in Container..."_ in RDEP. There's no longer a need to map an ssh agent socket or pass git configs into the environment either, as the host environment is accessible within the project shell. Swapping between Nix projects is just as easy as containerized projects _and_ makes use of the host environment configurations without much headache.

#### VM Dependence
Containers benefit from a great developer experience on Linux hosts, but not so much on macOS or Windows. On other platforms, there is a hard requirement of virtualizing the Linux kernel to use containers. Because of this, yet another layer of networking and file system overhead is incurred. This leads to slow build times and poor input latency. It's been a showstopper before when developing on other platforms and prevented the usage of familiar workflows. With Nix there's no need for a VM (except for WSL's magic), so one can build packages specific to their host and benefit from native performance.

#### Environment Isolation
Since the developer shell is overlaid on the host's environment, it still has easy access to host networking and display servers. Some terminal tools, for example [Balena CLI](https://github.com/balena-io/balena-cli), assume to always be in a privileged host environment where it can open browsers for SSO authentication. When using containers to pin the Balena CLI version as part of the environment, it makes this method of login difficult. The container needs to be configured for XDG opening or X forwarding to automatically open a browser. Ports also need to be forwarded for the listening Balena CLI server to complete authentication. With Nix, this process works just as smooth as one expects. It also avoids configuring new users or setting up sudo inside the container, which is another requirement by Balena CLI.

The lack of file system isolation while developing is a potential downside. The Nix shell does not isolate the user from the host file system like normal Nix builders do. Situations could arise where a new developer runs their program via the Nix shell, expects it to be isolated from their host, then has unintended overwrites. When running the build phase, any project execution happens in a dedicated Nix store, which is how most new users would expect the shell to behave as well; almost like a chroot. 

#### Image Layers
Nix projects also benefit from building self-contained dependencies. Since each package is built independently, they can be reused across projects without incurring a large amount of disk space in comparison to containers. When a container layer gets built, it is possible to stuff multiple dependencies into a single layer. If a single binary gets changed in this layer, the entire layer is rebuilt anew, and doubles the amount of space needed to have both layers; even though the difference between them is a single binary. Somewhat surprisingly, Nix also has the ability to build containers, using its normal dependency graph, to map each layer of the image to a single dependency. **This is a really powerful use of Nix** which allows for tiny container image updates. Each layer can be surgically diffed and replaced, drastically cutting down on the amount of data transferred. The alternative with Dockerfiles would be running `RUN apt-get install` or `RUN pip install` to force a new layer for each and every dependency included in the container. This approach also avoids needing lock files for `apt` or `pip` and will always yield the expected version!

#### Configuration Syntax
In comparison to Dockerfiles however, the Nix Expression Language is extremely foreign to most. It is heavily inspired by Haskell and other functional languages; which is a far cry from the more imperative approach of Dockerfiles where each statement can be mapped to a layer. With Nix, you are composing a graph of dependencies which may lead to complex, uncommented expressions where it is not immediately clear what the author intended. This isn't to say Dockerfiles entirely avoid similar ambiguity, but their behavior is closer to scripting which many audiences are already accustomed to.

#### Extension Support
In the case of extension management, RDEP allows developers to define project specific extensions inside the `devcontainer.json`. When a container project is opened, it will install all defined extensions inside the container instead of globally. This is a nice way to keep your global extensions to a minimum and minimize any conflicts between them that may arise. One project may use the _Black_ python formatter, whereas another may use _autopep8_, and each have multiple extensions to choose from. Nix by default does not allow defining extensions like this, however, this functionality could potentially be shimmed by another VS Codium extension. 


# Conclusion

Nix is neat. It has a higher learning curve than expected, but it shows a lot of potential in addressing the issues in RDEP and container workflows. A similar sentiment is held among the Nix community: they admit the barrier to entry, but overall find that it serves their needs well. This isn't limited to just individual experience either; [Tailscale](https://github.com/tailscale/tailscale-android/blob/main/flake.nix) and [Replit](https://blog.replit.com/powered-by-nix) use Nix as part of their production workflow too. Production usage may be surprising to some (it was for me), and not so surprising to others, as the Nix project started in 2008 but is [now seeing renewed interest](https://trends.google.com/trends/explore?date=2021-01-01%202022-08-05&geo=US&q=%2Fg%2F11bw4cknm7).

It will be exciting to follow the project's growth and possible wide adoption. Solving "It Works On My Machine (TM)" will be an ever illusive issue, but Nix's approach is a big step towards mitigating such time-intensive frustrations. It provides many container-like conveniences without deep ties to the Linux kernel and the added complexity of features irrelevant to dependency management.

__


So far, Nix passes my initial smoke tests and has been incorporated into my basic projects: like the environment for [this site](https://gitlab.com/kalebpace/kalebpace.gitlab.io/-/tree/main/site) and the build for my [LaTeX resume](https://gitlab.com/kalebpace/kalebpace.gitlab.io/-/tree/main/resume). If Nix doesn't break in more esoteric ways, it could easily replace how my projects are managed and greatly supplement others in need of containerization. 

Since this is my first long-form article ever, I feel a great deal of thanks is due for you the reader and to commend your endurance. It is greatly appreciated. Hopefully, you were able to take away a helpful analysis and opinion on Nix as a technology; and maybe even incorporate it into your next project 😁

----

# Too Long; Didn't Read

## Key Concepts

- **Nix** is a collection of tools: Nix the Package Manager, Nix the Expression Language, and NixOS
- Install Nix in **multi-user** mode; your system package manager should configure it like this already 
-  **Flakes** are most similar to docker-compose in managing the project and environments, **default.nix** is similar to Dockerfiles in building a final container. They intend to be the new way Nix projects are maintained
- **Nix Garbage Collection** is most similar to `$ docker prune`
- **nix-daemon** and _docker-daemon_ are similar in that they ensure images/artifacts are shared between users and dispatch actions on behalf of a non-root user
- To copy your project to the **Nix Store** for building, you must track all relevant files with git (if initialized, otherwise its the entire current directory)
- Troubleshooting commands or syntax is difficult for beginners due to **poor error reporting and spread-out documentation**

## Pros vs. RDEP Workflow
- Similar ease in moving between projects, with faster initialization times
- Purportedly better development experience on macOS and Windows WSL, due to the non-dependence on a hypervisor
- Priority support for building container images with the same Nix environment and efficient layer diffing
- An expressive, declarative, domain specific language to define your project environment and dependencies
- Reproducible builds without package manager specific lock files if desired (e.g. `pip requirements-freeze.txt`)
- No magic needed to pass git config and ssh agent information into a project

## Cons vs. RDEP Workflow
- Confusing documentation due to age of project and conflicting opinions in forums regarding the newest features
- Lack of tooling maturity and extensions which hurts wide adoption on VS Codium or other mainstream editors
- Can't readily or easily isolate extensions per workspace
- Errors with Nix are vague, hard to debug, and difficult to search for

## Recipe

Source Code: [nix-flake-rust-nightly-vscode](https://github.com/kalebpace/nix-flake-rust-nightly-vscode)
> By the end of this recipe, you should have a project folder that drops you into a shell with all project related dependencies. This should mimic the basic functionality of `.devcontainer` and _Reopen Folder in Container..._

1. [Install nix](https://nixos.org/download.html). Using your system's package manager is recommended, as in the case of Arch Linux, it sets up [build users](https://nixos.org/manual/nix/stable/installation/multi-user.html#setting-up-the-build-users) for you automatically. This installation type does require root, but is the most "docker-like" experience in operation. If you need rootless, checkout [advanced methods](https://nixos.wiki/wiki/Nix_Installation_Guide#nix_2.0.27s_native_method).

2. Enable experimental features for unified commands and flakes
    ```bash
    # /etc/nix/nix.conf

    #
    # https://nixos.org/manual/nix/stable/#sec-conf-file
    #

    # Unix group containing the Nix build user accounts
    build-users-group = nixbld

    # Disable sandbox
    # sandbox = false

    # enables the use of 'nix flake' and other subcommands
    extra-experimental-features = nix-command flakes

    # By default, nix only uses one builder. 
    # The following will allow nix to use as many jobs as the number of CPUs:
    max-jobs = auto
    ```

3. [Install VSCodium extensions](https://github.com/VSCodium/vscodium)
    ```json
    // .vscode/extensions.json
    {
      "recommendations": [
        // manages env variables based on current directory
        "mkhl.direnv",

        // provides highlighting and formatting for *.nix files
        "jnoortheen.nix-ide",

        // configures VSCodium to use the env direnv sets
        "arrterian.nix-env-selector"
      ]
    }
    ```

4. Initialize your project with Nix Flakes and set up `.envrc` for direnv detection
    ```bash
    # any arbitrary project directory
    $ cd ./workspace

    # will create a generic flake.nix 
    $ nix flake init --template templates#trivial

    # will create default.nix and shell.nix for compatability with flakes
    # and vscode extensions
    $ nix flake init --template templates#compat 

    # tell direnv to use flake environment by default
    $ echo 'use flake' > .envrc
    ```

5. Define your project environment. The [Reference](https://nixos.wiki/wiki/Nix_Expression_Language) provides much needed insight into keywords and syntax. 
    ```nix
    # flake.nix
    {
      # Define your default inputs. These inputs could be overriden by 
      # other users when using this flake to customize it to their needs
      # (which is out of scope for this template)
      inputs = {
        # I tend to prefer unstable channels as its easier to find 
        # github issues when things break
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

        # flake-utils helps us remove cross-platform boilerplate
        utils.url = "github:numtide/flake-utils";

        # Provides a nix 'overlay' with the nightly rust toolchain.
        # Per the project's description, it aims to replace rustup usage
        # in flake-based projects. Also ships with rust-analyzer-nightly
        fenix.url = "github:nix-community/fenix";
      };

      outputs = { self, nixpkgs, utils, fenix }:

        # Define a system environment for your machine (e.g. system.x86_64-linux)
        utils.lib.eachDefaultSystem (system:
          let
            pkgs = import nixpkgs { 
              # Inherit our current system environment configuration so nixpkgs
              # will fetch proper architectures, etc. 
              inherit system;

              # Apply the rust overlay which overrides any packages of 
              #the same name found in nixpkgs 
              overlays = [ fenix.overlay ];
            };

            # Define our desired toolchain based off a standard rust toolchain 
            # file. You could define the same components inside here, but 
            # rust-toolchain.toml is better documented, so it makes more sense.
            rust-toolchain = pkgs.fenix.fromToolchainFile {
              file = ./rust-toolchain.toml;

              # I cheated and used a dummy SHA to cause a conflict, where 
              # I then copied the conflicting SHA here to resolve the error. 
              # Unsure how to find the SHA "properly".  
              sha256 = "i2rzMf9nu5PXlOUk3LXBCVMRiTZDzlDW3x47/GPqAgw=";
            };
          in rec {

            # This is like starting a shell in a dev container.
            #
            # Define the shell we want to drop into when VSCodium loads or
            # 'nix develop' is run. 
            # 
            # 'with pkgs' scopes the following statement with that namespace,
            # so we don't need to type 'pkgs.rust-analyzer-nightly' and instead
            # directly reference it.
            devShell = with pkgs; mkShell {
              buildInputs = [
                rust-toolchain
                rust-analyzer-nightly
              ];
            };
          }
        );
    }
    ```
  
  6. Using `nix-env-selector` plugin installed in step 3, select `shell.nix` as default environment. This should configure VS Codium so that any shell opened in the window will drop you into the devShell declared above. **You may need to allow direnv access to the directory**.

> Finished! You should now have a project directory which initializes with rust-nightly toolchain the moment you open VS Codium. 🥳

</details>

