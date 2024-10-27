# Grafana Provisioning

This directory contains the provisioning configuration for Grafana dashboards, data sources, and alert notification channels. Provisioning allows us to version control and automatically configure Grafana settings, making it easier to share consistent configurations across team members.

## Directory Structure

```
provisioning/
├── dashboards/        # Dashboard provisioning configs and JSON files
│   └── dashboard.yml  # Dashboard provider configuration
├── datasources/       # Data source provisioning configs
│   ├── cloudwatch.yml # AWS CloudWatch data source
│   └── prometheus.yml # Prometheus data source
├── notifiers/         # Alert notification channel configs
│   └── notifier.yml   # Alert notification channel configuration
```

## How It Works

Grafana's provisioning system automatically loads configurations from these directories when the container starts. This means:

1. Data sources are automatically created/updated based on the YAML files in `datasources/`
2. Dashboards are automatically imported from the paths specified in `dashboard.yml`

## Sharing Dashboards

To share a dashboard with your team:

1. Export your dashboard from Grafana UI (Share Dashboard → Export → Save to file)
2. Place the JSON file in the `dashboards/` directory
3. Update `dashboard.yml` if needed to include the new file
4. Commit and push the changes

When team members pull and restart their Grafana containers, they'll automatically get the new dashboard.

## Configuration Details

### dashboard.yml
This file tells Grafana where to find dashboard JSON files and how to handle them:
- `path`: Directory containing dashboard JSON files
- `editable`: Whether users can edit provisioned dashboards
- `disableDeletion`: Prevents dashboard deletion via the UI

### datasources/*.yml
These files configure data source connections:
- Connection details (URLs, authentication)
- Default data source settings
- Access modes and other options

## Adding New Dashboards

1. Create your dashboard in Grafana
2. Export it to JSON
3. Add the JSON file to `dashboards/`
4. The dashboard will be automatically imported on container restart

Remember: Any changes to provisioned dashboards should be made through version control, not the Grafana UI, to maintain consistency across all instances.
