# NixOS Package & Module for TorrServer

[Русский](#русский) | [English](#english)

## Русский

Неофициальный Nix-пакет и модуль NixOS для [TorrServer](https://github.com/YouROK/TorrServer). Поддерживает архитектуры `x86_64-linux` и `aarch64-linux`, а также предоставляет две версии сборки: стандартную и **GStreamer** (с поддержкой HLS-стриминга, онлайн-транскодирования кодеков DTS/AC3 и конвертации HDR в SDR).

### ⚠️ Дисклеймер / Отказ от ответственности

- **Я НЕ являюсь создателем или разработчиком TorrServer.**
- Данный репозиторий содержит **исключительно код сборки (рецепт) пакета и модуль** для операционной системы NixOS.
- Все права на оригинальный продукт принадлежат его законному владельцу ([YouROK](https://github.com/YouROK)).
- Продукт распространяется «как есть», используйте на свой страх и риск.
    

### 🚀 Использование (NixOS Module) — Рекомендуемый способ

Поскольку TorrServer является фоновым сервисом, проще всего настроить его через готовый NixOS модуль.

1. Добавьте репозиторий в `inputs` вашего `flake.nix`:
    



```Nix
inputs = {
  torrserver = {
    url = "github:Damima3369/TorrServer";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

2. Подключите модуль в `outputs` вашего `flake.nix`:
    



```Nix
outputs = { self, nixpkgs, torrserver, ... }@inputs: {
  nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux"; # или "aarch64-linux"
    modules = [
      ./configuration.nix
      torrserver.nixosModules.default
    ];
  };
};
```

3. Включите и настройте сервис в `configuration.nix`:
    


```Nix
services.torrserver = {
  # Включить службу TorrServer
  enable = true;

  # Включить сборку с поддержкой GStreamer (для HLS-стриминга и транскодинга)
  # Установите в false, если вам нужен только чистый Direct Play (гораздо легче)
  enableGst = false;

  # Порт веб-интерфейса и HTTP API (--port)
  port = 8090;

  # IP-адрес привязки (--ip). Оставьте пустым (""), чтобы слушать все интерфейсы (0.0.0.0)
  bindAddress = "";

  # Путь к рабочей директории и базе данных (--path)
  dataDir = "/var/lib/torrserver";

  # Запуск базы данных в режиме «только для чтения» (--rdb)
  readOnlyDb = false;

  # Включить авторизацию по паролю на все HTTP-запросы (--httpauth)
  httpAuth = false;

  # Автоматически открыть в файерволе порты сервера и DLNA (8090, 9080, 1900 UDP и т.д.)
  openFirewall = true;

  # Дополнительные флаги запуска
  extraFlags = [
    # "--webdav"
    # "--ssl"
    # "--maxsize" "10737418240"
  ];
};
```

### 📦 Установка только пакета

Если вам нужен только бинарник без системного сервиса systemd:

#### Вариант 1.1: Прямое использование через Flakes


```Nix
environment.systemPackages = [
  # Версия с GStreamer (по умолчанию)
  inputs.torrserver.packages.${pkgs.system}.default
  # Или стандартная легкая версия:
  # inputs.torrserver.packages.${pkgs.system}.torrserver
];
```

#### Вариант 1.2: Подключение через Overlay



```Nix
# В flake.nix
nixpkgs.overlays = [ torrserver.overlays.default ];

# В configuration.nix
environment.systemPackages = with pkgs; [
  torrserver-gst # или torrserver
];
```

#### Вариант 2: Без Flakes (Классический NixOS)



```Nix
environment.systemPackages = [
  ((import (builtins.fetchGit {
    url = "https://github.com/Damima3369/TorrServer.git";
    ref = "main";
  }) { inherit pkgs; }).torrserver-gst)
];
```

### ⚡ Быстрый запуск без установки

Запустить сервер «на лету» без записи в конфигурацию системы:



```Bash
# Запуск версии с GStreamer
nix run github:Damima3369/TorrServer

# Запуск стандартной версии
nix run github:Damima3369/TorrServer#torrserver
```

## English

Unofficial Nix package and NixOS module for [TorrServer](https://github.com/YouROK/TorrServer). Supports `x86_64-linux` and `aarch64-linux` architectures, providing both standard and **GStreamer-enabled** builds (for HLS streaming, live audio/video transcoding, and HDR-to-SDR tone mapping).

### ⚠️ Disclaimer

- **I am NOT the creator or developer of TorrServer.**
- This repository contains **only the packaging code (derivation) and system module** for NixOS.
- All rights to the original software belong to its creator ([YouROK](https://github.com/YouROK)).
- This software is provided "as is", use it at your own risk.
    

### 🚀 Usage via NixOS Module (Recommended)

Since TorrServer runs as a background daemon, the cleanest integration method is using the provided systemd module.

1. Add this repository to `inputs` in your `flake.nix`:
    



```Nix
inputs = {
  torrserver = {
    url = "github:Damima3369/TorrServer";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

2. Import the module inside `outputs` in your `flake.nix`:
    



```Nix
outputs = { self, nixpkgs, torrserver, ... }@inputs: {
  nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux"; # or "aarch64-linux"
    modules = [
      ./configuration.nix
      torrserver.nixosModules.default
    ];
  };
};
```

3. Enable and configure the service inside your `configuration.nix`:
    



```Nix
services.torrserver = {
  # Enable the TorrServer systemd service
  enable = true;

  # Enable GStreamer support build variant (for HLS streaming & transcoding)
  # Set to false for a lightweight Direct Play only build
  enableGst = false;

  # HTTP Web UI and API port (--port)
  port = 8090;

  # IP address to bind to (--ip). Leave empty ("") to listen on all interfaces (0.0.0.0)
  bindAddress = "";

  # Path to database and state directory (--path)
  dataDir = "/var/lib/torrserver";

  # Open database in read-only mode (--rdb)
  readOnlyDb = false;

  # Require HTTP authorization for all incoming requests (--httpauth)
  httpAuth = false;

  # Automatically open required firewall ports (Web UI, DLNA DMS, SSDP)
  openFirewall = true;

  # Extra command-line flags passed to TorrServer
  extraFlags = [
    # "--webdav"
    # "--ssl"
    # "--maxsize" "10737418240"
  ];
};
```

### 📦 Standalone Package Installation

If you only want the executable binary without managing a system service:

#### Option 1.1: Direct Usage via Flakes



```Nix
environment.systemPackages = [
  # GStreamer build (default)
  inputs.torrserver.packages.${pkgs.system}.default
  # Or standard lightweight build:
  # inputs.torrserver.packages.${pkgs.system}.torrserver
];
```

#### Option 1.2: Clean Setup via Overlay



```Nix
# In flake.nix
nixpkgs.overlays = [ torrserver.overlays.default ];

# In configuration.nix
environment.systemPackages = with pkgs; [
  torrserver-gst # or torrserver
];
```

#### Option 2: Legacy / Non-Flakes



```Nix
environment.systemPackages = [
  ((import (builtins.fetchGit {
    url = "https://github.com/Damima3369/TorrServer.git";
    ref = "main";
  }) { inherit pkgs; }).torrserver-gst)
];
```

### ⚡ Try Without Installing

Run TorrServer instantly on demand without adding it to your system state:



```Bash
# Run GStreamer variant
nix run github:Damima3369/TorrServer

# Run standard variant
nix run github:Damima3369/TorrServer#torrserver
```
