# Стратегия собственного iNiR rice

## Рекомендуемая схема

Не смешивай исходники iNiR с системным репозиторием.

```text
march-taylor/nix
  └── NixOS, Home Manager, версии inputs, ISO

march-taylor/inir-rice
  └── fork snowarch/iNiR: QML, JS, scripts, assets
```

Причины:

- обновления системы и визуальные изменения имеют разный темп;
- история `nix` остаётся читаемой;
- upstream iNiR можно подключать как remote и регулярно вливать;
- системный flake переключается между upstream и fork одной строкой;
- rice можно тестировать локально без постоянной пересборки всей NixOS.

## Пока собственный fork не нужен

Текущий `flake.nix` использует:

```nix
inir.url = "github:snowarch/iNiR";
```

Обновление только iNiR:

```bash
nix flake update inir
sudo nixos-rebuild test --flake .#desktop
sudo nixos-rebuild switch --flake .#desktop
```

Пользовательские настройки iNiR продолжают храниться в его обычных config/state-файлах. Packaged QML находится в `/nix/store` и не редактируется на месте.

## Когда начнёшь менять QML

1. Создай fork `snowarch/iNiR` на GitHub, например `march-taylor/inir-rice`.
2. В fork добавь оригинальный репозиторий как upstream:

```bash
git clone git@github.com:march-taylor/inir-rice.git
cd inir-rice
git remote add upstream https://github.com/snowarch/iNiR.git
git fetch upstream
```

3. Используй небольшие тематические коммиты:

```text
rice(bar): replace workspace component
rice(theme): add custom palette API
rice(audio): redesign volume popup
```

4. Переключи input в `march-taylor/nix/flake.nix`:

```nix
inir.url = "github:march-taylor/inir-rice";
```

5. Обнови lock и протестируй:

```bash
nix flake lock --update-input inir
sudo nixos-rebuild test --flake .#desktop
```

## Вливание upstream

В fork:

```bash
git fetch upstream
git switch main
git rebase upstream/main
# либо git merge upstream/main
git push --force-with-lease
```

Для спокойных обновлений лучше:

- не переименовывать массово upstream-файлы без необходимости;
- добавлять свои компоненты в отдельные каталоги;
- держать переключатели реализации в нескольких центральных файлах;
- не форматировать весь проект одним коммитом;
- сначала вливать upstream, затем отдельным коммитом исправлять несовместимости rice.

## Локальная разработка

Nix позволяет временно заменить GitHub input локальным checkout без изменения `flake.nix`:

```bash
sudo nixos-rebuild test --flake .#desktop \
  --override-input inir path:/home/march/projects/inir-rice
```

Это удобно для проверки пакета, но каждая сборка копирует исходники в Nix store. Для быстрого QML-цикла можно отдельно запускать checkout способом разработки, который поддерживает сам iNiR, а NixOS-конфигурацию оставить на стабильном input.

Когда изменение готово:

```bash
cd ~/projects/inir-rice
git add .
git commit -m "rice(panel): add custom media module"
git push

cd /etc/nixos
nix flake update inir
sudo nixos-rebuild test --flake .#desktop
```

## Почему не submodule

Git submodule технически возможен, но для этой схемы обычно хуже flake input:

- flake уже фиксирует commit iNiR в `flake.lock`;
- submodule создаёт второй механизм фиксации той же зависимости;
- установка из архива GitHub и работа с dirty tree становятся сложнее;
- обновление input через `nix flake update inir` проще.

Поэтому отдельный fork + flake input — основной рекомендуемый путь.
