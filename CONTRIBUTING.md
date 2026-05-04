# Contributing

Contributions are welcome! Here are some ways you can help:

- Report bugs via GitHub Issues
- Suggest new services to add
- Improve documentation
- Test on different Pi hardware and report results

## Adding a New Service

1. Add the service to `docker-compose.yml`
2. Add a tile to `config/homepage/services.yaml`
3. Add the service to the README feature table
4. Update the setup script if needed
5. Submit a pull request

## Guidelines

- No personal information in commits
- Use generic placeholders (`YOUR_PI_IP`, `Your/Timezone`) not real values
- Test your changes before submitting
- Keep passwords out of all files — use variables or prompts
