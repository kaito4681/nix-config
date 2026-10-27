{ pkgs, githubName, githubEmail, ... }:

{
  home.packages = [ pkgs.ghq ];

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = githubName;
        email = githubEmail;
      };

      init.defaultBranch = "main";
      core.editor = "nvim";
      sequence.editor = "nvim";

      alias = {
        s = "status";
        ss = "status --short";
        sb = "status --short --branch";

        b = "branch";
        ba = "branch -a";
        co = "checkout";
        cb = "checkout -b";
        sw = "switch";
        swc = "switch -c";

        d = "diff";
        ds = "diff --staged";

        a = "add";
        aa = "add --all";

        c = "commit";
        cm = "commit -m";
        ca = "commit --amend";
        can = "commit --amend --no-edit";

        l = "log --oneline";
        lg = "log --graph --oneline --decorate --all";

        sh = "stash";
        sk = "stash --keep-index";
        sku = "stash --keep-index --include-untracked";
        sl = "stash list";
        sp = "stash pop";

        rt = "reset";
        rs = "restore";

        w = "worktree";
        wt = "worktree";
        wa = "worktree add";
        wta = "worktree add";
        wr = "worktree remove";
        wtr = "worktree remove";
        wl = "worktree list";
        wtl = "worktree list";
        wp = "worktree prune";
        wtp = "worktree prune";

        f = "fetch";
        p = "pull";
        ps = "push";

        m = "merge";
        rb = "rebase";
        rbc = "rebase --continue";
        rba = "rebase --abort";
      };

      ghq = {
        root = "~/ghq";
        user = githubName;
      };

      core.pager = "delta";
    };

    ignores = [
      "*~"
      ".DS_Store"
    ];

    lfs.enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
  };
}
