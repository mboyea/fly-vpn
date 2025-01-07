#--------------------------------
# Author : Matthew Boyea
# Origin : https://github.com/mboyea/fly-vpn
# Description : convert .env file to a nix attribute set
# Nix Usage : envVars = import ./env.nix { inherit pkgs; };
#--------------------------------
{
  pkgs ? import <nixpkgs> {},
}: let
  # filter out nameless attributes from the attribute set
  envVars = pkgs.lib.attrsets.filterAttrs
    (name: value: name != "")
    # convert the list of name value pairs to an attribute set
    (builtins.listToAttrs (
      # for each line from the file, map it to a name value pair
      builtins.map
      (string: let
        # split the string at "="
        splitString = pkgs.lib.strings.splitString "=" string;
      in {
        # set name to lhs excluding "\""
        name = builtins.replaceStrings ["\""] [""] (builtins.elemAt splitString 0);
        # set value to rhs excluding "\""
        value = builtins.replaceStrings ["\""] [""] (builtins.elemAt splitString 1);
      })
      # get a list with each line from the file .env
      (pkgs.lib.strings.splitString "\n"
        (builtins.readFile ./.env)
      )
    ));
in envVars
