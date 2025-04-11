# Docker MSA Tool

This is a Multiple Sequence Alignment (MSA) tool built with R Shiny and containerized with Docker.

## Prerequisites

- Docker installed on your system
- Git for version control

## Local Development

1. Clone the repository:
```bash
git clone <your-repository-url>
cd docker-msa
```

2. Build the Docker image:
```bash
docker build -t msa-tool .
```

3. Run the container:
```bash
docker run -p 3838:3838 msa-tool
```

4. Access the application at `http://localhost:3838`

## GitHub Deployment

1. Fork this repository
2. Enable GitHub Actions in your repository settings
3. Create a Personal Access Token with `packages:read` and `packages:write` permissions
4. Add the token as a repository secret named `GITHUB_TOKEN`
5. Push changes to the main branch to trigger automatic deployment

## Using the Application

1. Upload your FASTA format sequences
2. Configure alignment parameters
3. Run the alignment
4. Download the results

## Technical Details

- Base image: rocker/shiny:4.3.3
- R packages: msa, Biostrings, and other dependencies
- Exposed port: 3838

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request 