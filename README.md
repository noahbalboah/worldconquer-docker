# World Conquer Online - Docker Deployment

Docker deployment configuration for the [World Conquer Online (Comet)](https://gitlab.com/felipevendramini/comet) Conquer Online private server emulator.

## Credits

- **Comet** by [Gareth Jensen "Spirited"](https://gitlab.com/spirited/comet) - Original server emulator
- **World Conquer (FTW fork)** by [Felipe Vieira Vendramini](https://gitlab.com/felipevendramini/comet) - Extended fork targeting patch 5187

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) (to build the server)
- The Conquer Online 5187 game client (not provided)
- Game data files (`ini/` and `map/` directories from a built server)

## Quick Start

1. **Clone the Comet server repository and build it:**

   ```bash
   git clone https://gitlab.com/felipevendramini/comet.git worldconquer
   cd worldconquer
   dotnet restore
   dotnet build
   ```

2. **Copy the Docker files from this repo into the server directory:**

   ```bash
   cp /path/to/worldconquer-docker/Dockerfile .
   cp /path/to/worldconquer-docker/docker-compose.yml .
   cp /path/to/worldconquer-docker/.dockerignore .
   ```

3. **Set up game data:**

   The game server requires `ini/` and `map/` directories. These are typically excluded from git (`.gitignore`). Place them so they are accessible on the host, then update the volume paths in `docker-compose.yml`:

   ```yaml
   volumes:
     - /path/to/your/ini:/app/ini:ro
     - /path/to/your/map:/app/map:ro
   ```

4. **Import the database:**

   ```bash
   docker compose up -d db
   # Wait for DB to be healthy, then import the SQL scripts:
   docker exec -i comet-db mariadb -u root -ppassword < sql/comet.account.sql
   docker exec -i comet-db mariadb -u root -ppassword < sql/comet.game.sql
   ```

5. **Configure the realm:**

   Update the `realm` table with your server's IP address:

   ```sql
   UPDATE account_zf.realm
   SET GameIPAddress = 'YOUR_SERVER_IP'
   WHERE RealmID = 2;
   ```

   > The client does not support `127.0.0.1` - use your machine's LAN IP (e.g. `192.168.x.x`).

6. **Start everything:**

   ```bash
   docker compose up -d
   ```

7. **Create a game account:**

   ```bash
   docker exec -i comet-db mariadb -u root -ppassword account_zf -e "
     INSERT INTO account (Username, Password, Salt, AuthorityID, StatusID)
     VALUES ('admin', SHA2(CONCAT('admin123', 'mysalt'), 256), 'mysalt', 3, 1);
   "
   ```

   > Passwords must be alphanumeric only (client limitation).

## Architecture

```
docker compose up -d
```

Starts three services using host networking:

| Service | Container | Port | Description |
|---------|-----------|------|-------------|
| **db** | `comet-db` | 3306 | MariaDB database |
| **account** | `comet-account` | 9958 (client), 9865 (realm) | Account server - authenticates players |
| **game** | `comet-game` | 5816 | Game server - handles game world |

### Why host networking?

The game server connects to the account server's realm port via `127.0.0.1:9865` (configured in `Comet.Game.config`). Host networking is the simplest way to maintain this localhost connection between containers without modifying server code.

## Configuration

### Server config files

The config files are baked into the Docker image during build. Database hostname and password are overridden via command-line arguments in `docker-compose.yml`:

- `Comet.Account.config` - Account server settings
- `Comet.Game.config` - Game server settings

### Important: Change default passwords!

The default configuration uses insecure passwords for ease of setup. **Change these before exposing to any network:**

| What | Default | Where to change |
|------|---------|-----------------|
| MariaDB root password | `password` | `docker-compose.yml` → `MARIADB_ROOT_PASSWORD` and entrypoint `/Database:Password=` args |
| Game admin account | `admin` / `admin123` | `account_zf.account` table |
| Realm credentials | `uOIMI9WHOMooKY0x` / `epPQ8dTJhtxxCobJ` | `account_zf.realm` table and `Comet.Game.config` → `GameNetwork.Username/Password` |

### Database volume

By default, the database data is stored at the path specified in `docker-compose.yml`. Update this path to match your setup:

```yaml
volumes:
  - /path/to/your/db/data:/var/lib/mysql
```

## Managing the Server

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f game

# Restart a specific service
docker compose restart game

# Rebuild after code changes
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Client Setup

Configure your Conquer Online 5187 client to connect to the server:

- **LoaderSet.ini**: Set `IPAddress` to the server's IP
- **config.json**: Set `LoginHost` and `GameHost` to the server's IP

Passwords in the client must be **alphanumeric only** (no special characters).

## License

This Docker deployment configuration is provided as-is for educational purposes.

The underlying Comet server is copyright Gareth Jensen "Spirited" - see the [original repository](https://gitlab.com/spirited/comet) for license details. The World Conquer fork is by Felipe Vieira Vendramini - see [the fork](https://gitlab.com/felipevendramini/comet) for additional credits.

Conquer Online is a registered trademark of TQ Digital Entertainment. This project is not affiliated with TQ Digital Entertainment.
