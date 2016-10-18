# -*- mode: bash; tab-width: 2; -*-
# vim: ts=2 sw=2 ft=bash noet

if [ ! -s ${HOME}/.yarn ]; then
  ln -sf {{code_dir}}/.yarn/yarn ${HOME}/.yarn
fi

if [ ! -s ${HOME}/.yarn-config ]; then
  ln -sf {{code_dir}}/.yarn/yarn-config ${HOME}/.yarn-config
fi

if [ ! -s ${HOME}/.yarn-cache ]; then
  ln -sf {{code_dir}}/.yarn/yarn-cache ${HOME}/.yarn-cache
fi
