# -*- mode: bash; tab-width: 2; -*-
# vim: ts=2 sw=2 ft=bash noet

# Copy the code into the live directory which will be used to run the app
publish_release() {
  nos_print_bullet "Moving code into app directory..."
  rsync -a $(nos_code_dir)/ $(nos_app_dir)
}

# Determine the nodejs runtime to install. This will first check
# within the Boxfile, then will rely on default_runtime to
# provide a sensible default
runtime() {
  echo $(nos_validate \
    "$(nos_payload "config_runtime")" \
    "string" "$(default_runtime)")
}

# Provide a default nodejs version.
default_runtime() {
  packagejs_runtime=$(package_json_runtime)

  if [[ "$packagejs_runtime" = "false" ]]; then
    echo "nodejs-4.4"
  else
    echo $packagejs_runtime
  fi
}

# todo: extract the contents of package.json
#   Will need https://stedolan.github.io/jq/
#   https://github.com/heroku/heroku-buildpack-nodejs/blob/master/lib/json.sh#L17
#   https://github.com/heroku/heroku-buildpack-nodejs/blob/master/bin/compile#L73
package_json_runtime() {
  echo "false"
}

# Install the nodejs runtime along with any dependencies.
install_runtime_packages() {
  pkgs=("$(runtime)" "python")
  
  # add any client dependencies
  pkgs+=("$(query_dependencies)")

  nos_install ${pkgs[@]}
}

# Uninstall build dependencies
uninstall_build_dependencies() {
  nos_uninstall "python"
}

# compiles a list of dependencies that will need to be installed
query_dependencies() {
  deps=()

  # mysql
  if [[ `grep 'mysql' $(nos_code_dir)/package.json` ]]; then
    deps+=(mysql-client)
  fi
  # memcache
  if [[ `grep 'memcache' $(nos_code_dir)/package.json` ]]; then
    deps+=(libmemcached)
  fi
  # postgres
  if [[ `grep 'postgres' $(nos_code_dir)/package.json` ]]; then
    deps+=(postgresql94-client)
  fi
  # redis
  if [[ `grep 'redis\|spade\|rebridge' $(nos_code_dir)/package.json` ]]; then
    deps+=(redis)
  fi
  
  echo "${deps[@]}"
}

# set the runtime in a file inside of node_modules so that if the
# runtime changes between deploys, we can blast the node_modules
# cache and build fresh.
persist_runtime() {
  if [[ -d $(nos_code_dir)/node_modules ]]; then
    echo "$(runtime)" > $(nos_code_dir)/node_modules/runtime
  fi
}

# check the runtime that was set at the last deploy, and ensure it
# hasn't changed. If it has changed, we'll return false.
check_runtime() {
  if [[ ! -d $(nos_code_dir)/node_modules ]]; then
    echo "true"
    return
  fi

  if [[ "$(cat $(nos_code_dir)/node_modules/runtime)" =~ ^$(runtime)$ ]]; then
    echo "false"
  else
    echo "true"
  fi
}

# If the package.json has changed since the previous deploy it should
# be rebuilt to ensure unused packages are purged.
npm_rebuild() {
  if [[ "$(check_runtime)" = "false" ]]; then
    cd $(nos_code_dir)
    nos_run_process "Rebuilding npm modules" "npm rebuild"
    cd - > /dev/null
  fi
}

# Installing dependencies from the package.json is done with npm install.
npm_install() {
  if [[ -f $(nos_code_dir)/package.json ]]; then

    cd $(nos_code_dir)
    nos_run_process "Installing npm modules" "npm install"
    cd - > /dev/null
  fi
}

# Prune node modules that are no longer needed
npm_prune() {
  if [[ -f $(nos_code_dir)/package.json ]]; then

    cd $(nos_code_dir)
    nos_run_process "Pruning npm modules" "npm prune"
    cd - > /dev/null
  fi
}
