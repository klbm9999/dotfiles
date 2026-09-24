### Setting up
Install git

Start by installing determinate nix
`curl -fsSL https://install.determinate.systems/nix | sh -s -- install`

then run once for the first switch
`nix run home-manager -- switch --flake .#bhanu`

After the first switch, once home-manager.enable=true has installed the command, just run
`home-manager switch --flake .#bhanu`
