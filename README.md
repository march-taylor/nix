# NixOS + Niri + iNiR

Декларативная конфигурация NixOS с:

- Niri через `sodiboo/niri-flake`;
- iNiR через официальный flake `snowarch/iNiR`;
- Home Manager для пользовательских программ и настроек;
- минимальным установочным ISO;
- отдельным offline-образом, содержащим closure целевой системы;
- структурой, в которой системный конфиг и собственный rice не смешиваются.

> Конфигурация рассчитана на современный UEFI-компьютер `x86_64-linux`. Перед установкой обязательно проверь `settings.nix` и замени шаблонный `hardware-configuration.nix` файлом, сгенерированным на целевой машине.

## Главная идея

Этот репозиторий — источник истины для системы:

```text
Git history
  + flake.nix
  + flake.lock
  + NixOS modules
  + Home Manager
  = воспроизводимая система
```

Сам iNiR не копируется внутрь репозитория. Он подключён как flake input и фиксируется в `flake.lock`. Это позволяет обновлять upstream отдельно:

```bash
nix flake update inir
sudo nixos-rebuild switch --flake .#desktop
```

Для глубокой правки QML рекомендуется отдельный fork iNiR. Подробности находятся в [`docs/RICE.md`](docs/RICE.md).

## Структура

```text
.
├── flake.nix                         # inputs и системные outputs
├── settings.nix                      # имя пользователя, hostname, локаль
├── justfile                          # короткие команды обслуживания
├── hosts/
│   └── desktop/
│       ├── default.nix               # точка входа конкретной машины
│       └── hardware-configuration.nix
├── modules/
│   ├── core/default.nix              # boot, users, Nix, сеть, локаль
│   ├── hardware/default.nix          # звук, Bluetooth, firmware
│   └── desktop/
│       ├── default.nix               # greetd
│       └── niri.nix                  # Niri + iNiR
├── home/
│   └── march/
│       ├── default.nix               # Home Manager entrypoint
│       ├── programs.nix              # пользовательские программы
│       └── niri.nix                  # бинды и layout Niri
├── installer/
│   ├── iso.nix                       # небольшой сетевой installer ISO
│   └── offline.nix                   # ISO с closure целевой системы
└── docs/
    └── RICE.md                       # стратегия собственного rice
```

## 1. Настрой параметры

Отредактируй [`settings.nix`](settings.nix):

```nix
{
  username = "march";
  fullName = "March Taylor";
  hostname = "nixos";
  system = "x86_64-linux";
  stateVersion = "26.05";
  timezone = "Europe/Berlin";
  locale = "en_US.UTF-8";
}
```

Если меняешь `username`, также переименуй каталог:

```bash
mv home/march home/НОВОЕ_ИМЯ
```

`stateVersion` для новой установки в 2026 году оставляй `26.05`. После установки не повышай его просто вместе с обновлением системы.

## 2. Создай и закоммить `flake.lock`

В первом коммите lock-файла ещё нет, потому что он должен быть сгенерирован Nix. Выполни:

```bash
nix flake lock
nix flake check

git add flake.lock
git commit -m "chore: lock flake inputs"
git push
```

После этого версии Nixpkgs, Home Manager, Niri и iNiR будут зафиксированы.

## Установка на уже работающий NixOS

Сначала сохрани аппаратный конфиг:

```bash
sudo cp /etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix
```

Затем установи репозиторий:

```bash
sudo mv /etc/nixos /etc/nixos.backup
sudo git clone https://github.com/march-taylor/nix /etc/nixos
sudo cp /tmp/hardware-configuration.nix \
  /etc/nixos/hosts/desktop/hardware-configuration.nix
sudo chown -R "$USER":users /etc/nixos

cd /etc/nixos
$EDITOR settings.nix
nix flake lock
```

Сначала используй тестовую активацию:

```bash
sudo nixos-rebuild test --flake .#desktop
```

Если Niri и вход в систему работают:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

Задай пароль пользователю, если он ещё не установлен:

```bash
sudo passwd march
```

Замени `march`, если изменил `settings.username`.

## Чистая установка с официального NixOS ISO

Самый надёжный первый путь — официальный graphical/minimal ISO NixOS 26.05 и этот Git-репозиторий.

### 1. Загрузись с ISO и подключи интернет

Для Wi-Fi в консоли можно использовать:

```bash
nmtui
```

### 2. Разметь и смонтируй диск

Разметка уничтожает данные. Проверь имя диска через `lsblk` и не копируй команды вслепую.

Для UEFI нужны как минимум:

- EFI System Partition, FAT32, обычно 512 MiB–1 GiB;
- корневой раздел, например ext4 или btrfs.

Удобно использовать `cfdisk`:

```bash
sudo -i
lsblk
cfdisk /dev/nvme0n1
```

После создания разделов отформатируй их. Пример для NVMe, где `p1` — EFI, `p2` — root:

```bash
mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

Для SATA-диска имена обычно выглядят как `/dev/sda1` и `/dev/sda2`.

### 3. Сгенерируй аппаратную конфигурацию

```bash
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix
rm -rf /mnt/etc/nixos
```

### 4. Клонируй репозиторий

```bash
git clone https://github.com/march-taylor/nix /mnt/etc/nixos
cp /tmp/hardware-configuration.nix \
  /mnt/etc/nixos/hosts/desktop/hardware-configuration.nix

cd /mnt/etc/nixos
nano settings.nix
nix flake lock
```

Репозиторий сейчас приватный. В live ISO обычный HTTPS clone потребует GitHub credentials. Практичные варианты:

- временно сделать репозиторий публичным на время установки;
- использовать GitHub personal access token;
- заранее собрать собственный ISO из этого репозитория;
- положить копию репозитория на флешку рядом с ISO.

### 5. Установи систему

```bash
nixos-install --flake /mnt/etc/nixos#desktop
```

После установки задай пароль обычному пользователю:

```bash
nixos-enter --root /mnt -c 'passwd march'
```

Затем перезагрузи компьютер:

```bash
reboot
```

## Первый запуск

Вход выполняется через `greetd`/`tuigreet`, после чего запускается `niri-session`. iNiR стартует как user systemd service, привязанный именно к сессии Niri.

Полезные команды диагностики:

```bash
systemctl --user status inir.service
inir logs --full
niri msg version
journalctl --user -u inir.service -b
```

## Основные бинды

| Комбинация | Действие |
|---|---|
| `Mod+Return` | терминал Foot |
| `Mod+E` | Nautilus |
| `Mod+Space` | overview iNiR |
| `Mod+V` | clipboard iNiR |
| `Mod+,` | настройки iNiR |
| `Mod+/` | cheatsheet iNiR |
| `Mod+Alt+L` | lock screen |
| `Mod+Shift+S` | снимок области |
| `Mod+Q` | закрыть окно |
| `Mod+H/J/K/L` | перемещать фокус |
| `Mod+Shift+H/J/K/L` | перемещать окна/колонки |

Раскладка переключается через `Super+Space` и по умолчанию содержит `us,ru`.

## Ежедневные команды

Через `just`:

```bash
just check
just build
just test
just switch
just update
just update-inir
```

Без `just`:

```bash
nix flake check
sudo nixos-rebuild build --flake .#desktop
sudo nixos-rebuild test --flake .#desktop
sudo nixos-rebuild switch --flake .#desktop
```

## Обновление

Обновить только iNiR:

```bash
cd /etc/nixos
nix flake update inir
sudo nixos-rebuild test --flake .#desktop
sudo nixos-rebuild switch --flake .#desktop

git add flake.lock
git commit -m "chore: update iNiR"
git push
```

Обновить всё:

```bash
nix flake update
sudo nixos-rebuild test --flake .#desktop
sudo nixos-rebuild switch --flake .#desktop
```

Не используй `inir update` для Nix-установки: пакет контролируется flake input.

## Откат

Текущую тестовую конфигурацию можно отменить перезагрузкой. Для отката активной конфигурации:

```bash
sudo nixos-rebuild switch --rollback
```

Также предыдущие поколения доступны в меню systemd-boot.

Если проблема пришла из обновлённого `flake.lock`:

```bash
git restore --source=HEAD~1 flake.lock
sudo nixos-rebuild switch --flake .#desktop
```

## Сборка собственного ISO

Сетевой installer содержит этот репозиторий и установочные инструменты, но пакеты целевой системы при установке могут скачиваться:

```bash
nix build .#installer-iso
ls result/iso/
```

Offline-образ дополнительно включает closure `nixosConfigurations.desktop` и исходники flake inputs:

```bash
nix build .#offline-installer-iso
ls result/iso/
```

Offline ISO заметно больше и привязан к текущему `flake.lock` и целевой конфигурации. Обязательно проверь его в виртуальной машине перед реальной установкой.

После загрузки собственного ISO копия репозитория находится по адресу:

```text
/etc/nixos-template
```

Она находится в Nix store и доступна только для чтения. Для установки сделай writable-копию:

```bash
cp -rL /etc/nixos-template /tmp/nixos-config
chmod -R u+w /tmp/nixos-config
```

После монтирования целевой системы скопируй конфиг в `/mnt/etc/nixos`, замени `hardware-configuration.nix` и запускай `nixos-install`.

## Свой rice

Системный репозиторий и исходники оболочки лучше держать отдельно:

- `march-taylor/nix` — NixOS, Home Manager, выбор версии iNiR;
- отдельный fork iNiR — QML, JavaScript, скрипты и визуальные модули rice.

Так системные коммиты не смешиваются с тысячами upstream-файлов оболочки, а обновления iNiR можно вливать обычным merge/rebase. См. [`docs/RICE.md`](docs/RICE.md).

## Секреты

Не помещай в обычные `.nix` файлы:

- пароли;
- Wi-Fi PSK;
- API-токены;
- приватные SSH-ключи;
- cookies и browser profiles.

Flake source и построенные конфигурации попадают в `/nix/store`, который нельзя считать секретным хранилищем. Для будущих секретов используй `sops-nix` или `agenix`.

## Что нужно адаптировать под железо

Обязательно проверь:

- `hosts/desktop/hardware-configuration.nix`;
- драйвер NVIDIA, если используется NVIDIA;
- имена и масштаб мониторов в `home/march/niri.nix`;
- раскладки клавиатуры;
- `settings.nix`;
- необходимость шифрования и выбранную файловую систему.

Для NVIDIA лучше добавить отдельный модуль после того, как будет известна точная модель GPU и режим hybrid/offload.