# Environment-Specific Deployment Guide

This repository now supports environment-specific deployments with separate configurations for development and production environments.

## Directory Structure

```
docker-compose-ics/
├── environments/
│   ├── dev/
│   │   ├── docker-compose.yml      # Development configuration
│   │   ├── .env.example           # Development environment variables
│   │   └── README.md              # Development-specific documentation
│   └── prod/
│       ├── docker-compose.yml      # Production configuration
│       ├── .env.example           # Production environment variables
│       └── README.md              # Production-specific documentation
├── .harness/                      # Harness deployment configuration
├── init-scripts/                  # Database initialization scripts
├── docker-compose.yml             # Legacy root configuration (for backward compatibility)
└── README-environments.md         # This file
```

## Quick Start

### Development Environment
```bash
cd environments/dev
cp .env.example .env
# Edit .env with your development values
docker-compose up -d
# OR with podman
podman-compose up -d
```

### Production Environment
```bash
cd environments/prod
cp .env.example .env
# Edit .env with your production values
docker-compose up -d
# OR with podman
podman-compose up -d
```

## Environment Differences

### Development (`environments/dev/`)
- **Image Tags**: `latest` for development builds
- **Logging**: Debug level logging enabled
- **Container Names**: Suffixed with `-dev`
- **Networks**: Isolated development network
- **Volumes**: Separate development volumes
- **Health Checks**: More frequent for faster feedback
- **Resource Limits**: No limits for development flexibility

### Production (`environments/prod/`)
- **Image Tags**: `stable` for production builds
- **Logging**: WARN level for performance
- **Container Names**: Suffixed with `-prod`
- **Networks**: Isolated production network
- **Volumes**: Separate production volumes
- **Health Checks**: Optimized intervals
- **Resource Limits**: CPU and memory constraints
- **Security**: Hardened security settings
- **JVM Tuning**: Production-optimized JVM settings

## Harness Deployment

The Harness deployment configuration supports both environments:

### Development Deployment
```bash
# Use development input set
harness pipeline execute --input-set development_environment_input_set
```

### Production Deployment
```bash
# Use production input set
harness pipeline execute --input-set production_environment_input_set
```

## Docker vs Podman Compatibility

Both environments are compatible with:
- **Docker Compose**: `docker-compose up -d`
- **Podman Compose**: `podman-compose up -d`

## Services

### ICS Service
- **Development**: `ics-service-dev` on ports 9090/9091
- **Production**: `ics-service-prod` on ports 9090/9091

### External Oracle Database
- **Host**: `infdev-ora01a.tcmis.com:1521`
- **Service**: `ICSDEV`
- **Connection**: Shared external database for both environments

## Environment Variables

Each environment has its own `.env.example` file with environment-specific defaults:

### Common Variables
- `TCMIS_DB_SECRET`: Database password
- `ORACLE_ROOT_PASSWORD`: Oracle root password

### Environment-Specific Variables
- Development: Debug settings, relaxed security
- Production: Performance tuning, security hardening

## Migration from Root Configuration

The root `docker-compose.yml` is maintained for backward compatibility but new deployments should use environment-specific configurations:

```bash
# Old way (still works)
docker-compose up -d

# New way (recommended)
cd environments/dev  # or environments/prod
docker-compose up -d
```

## Troubleshooting

### Port Conflicts
Each environment uses the same ports but different networks. To run both simultaneously, modify port mappings in one environment.

### Volume Conflicts
Each environment uses separate named volumes (`*-dev` vs `*-prod`) to avoid data conflicts.

### Network Isolation
Each environment has its own network (`ics-network-dev` vs `ics-network-prod`) for complete isolation.

## Best Practices

1. **Always use environment-specific configurations** for new deployments
2. **Test in development** before deploying to production
3. **Use secure passwords** in production `.env` files
4. **Monitor resource usage** in production environment
5. **Regular backups** of production volumes
6. **Keep environment configurations in sync** for consistency

## Support

For environment-specific issues:
- Development: See `environments/dev/README.md`
- Production: See `environments/prod/README.md`
- Harness: See `.harness/README-harness-deployment.md`
