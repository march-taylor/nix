# NixOS + Niri + iNiR

Воспроизводимая конфигурация для текущего компьютера Mart:

- Gigabyte B550M AORUS ELITE;
- AMD Ryzen 5 5600;
- AMD Radeon RX 7800 XT;
- ADATA LEGEND 960 1 TB — `/dev/nvme0n1`;
- 32 GiB RAM;
- UEFI;
- пользователь `mart`;
- Niri + iNiR + Home Manager.

## Важное предупреждение

`hosts/desktop/disko.nix` полностью очищает **только**:

```text
/dev/nvme0n1 — ADATA LEGEND 960, примерно 1 TB
```

USB-накопитель:

```text
/dev/sda — Kingston DataTraveler, примерно 115 GB
```

не указан в Disko и не должен изменяться.

Перед установкой сохрани все нужные данные с NVMe. Установка уничтожит существующий CachyOS и все разделы на `/dev/nvme0n1`.

## Что будет установлено

### Рабочее окружение

- Niri;
- iNiR из upstream `snowarch/iNiR`;
- greetd/tuigreet;
- PipeWire;
- NetworkManager;
- Bluetooth;
- GNOME Keyring;
- Flatpak и AppImage support;
- Home Manager.

### Приложения

- VSCodium;
- Zen Browser;
- Discord с Equicord и OpenASAR через Nixcord;
- AyuGram Desktop;
- Steam;
- Proton-GE и Protontricks;
- Gamescope, GameMode, MangoHud, GOverlay и ProtonUp-Qt;
- KeePassXC;
- Pear Desktop — YouTube Music-клиент с поддержкой плагинов;
- Kitty;
- Nautilus;
- mpv, imv, FFmpeg, yt-dlp;
- pavucontrol и Helvum;
- GParted;
- инструменты диагностики AMD/Vulkan/OpenCL.

> Equicord/OpenASAR изменяют официальный Discord-клиент. Использование клиентских модификаций может противоречить правилам Discord; используешь их на свой риск.

## Разметка диска

Disko создаёт GPT:

```text
/dev/nvme0n1
├── ESP       2 GiB, FAT32, /boot
└── NixOS     оставшееся место, Btrfs
    ├── @root       /
    ├── @home       /home
    ├── @nix        /nix
    ├── @log        /var/log
    └── @snapshots  /.snapshots
```

Btrfs монтируется с `compress=zstd:3`, `noatime`, `ssd` и `discard=async`.

Дискового swap-раздела нет. Используется сжатый zram размером до 100% RAM.

## Установка с NixOS Graphical ISO

Graphical ISO подходит, но **не запускай Calamares**. Загрузись в live-систему и открой терминал.

### 1. Подключи интернет

Через интерфейс рабочего стола либо:

```bash
nmtui
```

Проверь сеть:

```bash
ping -c 3 cache.nixos.org
```

### 2. Получи репозиторий

Репозиторий приватный, поэтому обычный анонимный `git clone` не сработает.

Самый простой вариант для первой установки — временно сделать репозиторий публичным, затем:

```bash
cd /tmp
git clone https://github.com/march-taylor/nix.git nix-config
cd nix-config
```

После установки репозиторий можно снова сделать приватным.

Альтернатива: войти в GitHub через браузер live-системы, скачать ZIP репозитория, распаковать его и открыть распакованный каталог в терминале.

### 3. Ещё раз проверь диски

```bash
lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN
```

Ожидается:

```text
nvme0n1  около 954G  ADATA LEGEND 960
sda      около 115G  DataTraveler 3.0
```

Если имена или модель отличаются, **не запускай установщик** и сначала исправь `hosts/desktop/disko.nix`.

### 4. Запусти защищённый установщик

Из корня репозитория:

```bash
sudo bash ./install.sh
```

Скрипт выполняет действия в таком порядке:

1. Показывает все диски.
2. Создаёт или обновляет `flake.lock`.
3. Запускает `nix flake check --no-build`.
4. Только после успешной проверки просит ввести:

   ```text
   ERASE /dev/nvme0n1
   ```

5. Размечает и форматирует NVMe через Disko.
6. Копирует репозиторий в `/mnt/etc/nixos`.
7. Выполняет `nixos-install`.
8. Просит установить пароль root.
9. Просит установить пароль пользователя `mart`.

При любой ошибке оценки Nix диск ещё не изменяется.

### 5. Перезагрузка

После сообщения об успешной установке:

```bash
reboot
```

Извлеки флешку, когда компьютер начнёт перезагружаться.

## Первый вход

Войди пользователем:

```text
mart
```

После входа должны автоматически запуститься Niri и iNiR.

Проверь:

```bash
systemctl --user status inir.service
inir logs --full
niri msg version
```

Проверка графики RX 7800 XT:

```bash
vulkaninfo --summary
glxinfo -B
vainfo
clinfo
```

## После первого запуска

Конфигурация находится в:

```text
/etc/nixos
```

Зафиксируй созданный установщиком lock-файл:

```bash
cd /etc/nixos
git status
git add flake.lock
git commit -m "chore: lock initial system inputs"
git push
```

`flake.lock` фиксирует точные версии Nixpkgs, Home Manager, Niri, iNiR, Zen, AyuGram, Nixcord и Disko.

## Применение изменений

Безопасная тестовая активация:

```bash
cd /etc/nixos
sudo nixos-rebuild test --flake .#desktop
```

Постоянная активация:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

Перед переключением можно только собрать систему:

```bash
sudo nixos-rebuild build --flake .#desktop
```

Через `just`:

```bash
just check
just build
just test
just switch
```

## Обновления

Обновить только iNiR:

```bash
cd /etc/nixos
nix flake update inir
sudo nixos-rebuild test --flake .#desktop
sudo nixos-rebuild switch --flake .#desktop
git add flake.lock
git commit -m "chore: update iNiR"
```

Обновить отдельные приложения:

```bash
nix flake update zen-browser
nix flake update ayugram-desktop
nix flake update nixcord
```

Обновить всё:

```bash
nix flake update
sudo nixos-rebuild test --flake .#desktop
sudo nixos-rebuild switch --flake .#desktop
```

Для Nix-установки iNiR не запускай `inir update`: версия управляется flake input.

## Откат

```bash
sudo nixos-rebuild switch --rollback
```

Предыдущие поколения также доступны в меню systemd-boot.

Если проблема появилась после обновления inputs:

```bash
cd /etc/nixos
git restore --source=HEAD~1 flake.lock
sudo nixos-rebuild switch --flake .#desktop
```

## Структура

```text
.
├── flake.nix
├── flake.lock
├── settings.nix
├── install.sh
├── hosts/
│   └── desktop/
│       ├── default.nix
│       ├── disko.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── core/default.nix
│   ├── hardware/default.nix
│   ├── gaming/default.nix
│   └── desktop/
│       ├── default.nix
│       └── niri.nix
├── home/
│   └── mart/
│       ├── default.nix
│       ├── programs.nix
│       ├── discord.nix
│       └── niri.nix
├── installer/
│   ├── iso.nix
│   └── offline.nix
└── docs/RICE.md
```

## iNiR и собственный rice

Сейчас используется чистый upstream:

```nix
inir.url = "github:snowarch/iNiR";
```

Системный репозиторий и исходники rice лучше не смешивать:

- `march-taylor/nix` — система, пакеты, Home Manager, Disko и ISO;
- будущий `march-taylor/inir-rice` — fork iNiR с QML, JS и собственными модулями.

Для перехода на fork достаточно изменить input:

```nix
inir.url = "github:march-taylor/inir-rice";
```

Локальная разработка без изменения `flake.nix`:

```bash
sudo nixos-rebuild test --flake .#desktop \
  --override-input inir path:/home/mart/projects/inir-rice
```

Подробности: [`docs/RICE.md`](docs/RICE.md).

## Сборка собственного ISO

Сетевой ISO:

```bash
nix build .#installer-iso
```

Offline ISO с closure целевой системы:

```bash
nix build .#offline-installer-iso
```

Образ появится в:

```text
result/iso/
```

## Секреты

Не добавляй напрямую в репозиторий:

- Wi-Fi пароли;
- API-токены;
- приватные SSH-ключи;
- пароли пользователей;
- KeePass-базу;
- browser profiles.

Для будущего декларативного управления секретами используй `sops-nix` или `agenix`.
