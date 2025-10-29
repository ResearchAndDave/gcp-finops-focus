# MCP Toolbox Setup Guide for FOCUS Queries

This guide walks you through setting up MCP Toolbox to enable natural language access to your FOCUS BigQuery cost data through Claude Desktop, Gemini CLI, or custom applications.

## What You'll Get

After setup, you can ask questions like:
- "What did we spend on Compute Engine last month?"
- "Show me our fastest growing services"
- "When will we hit our budget limit?"
- "Which resources are untagged?"
- "Forecast our costs for next quarter"

And get instant answers from your FOCUS data.

---

## Prerequisites

### Required

1. **GCP Project** with billing enabled
2. **FOCUS BigQuery View** already deployed (see FOCUS_DEPLOYMENT_GUIDE.md)
3. **gcloud CLI** installed and configured
4. **Application Default Credentials** (ADC) configured

### Optional (for Claude Desktop integration)

5. **Claude Desktop** app installed
6. **macOS, Linux, or Windows** (MCP Toolbox supports all platforms)

---

## Part 1: Install MCP Toolbox

### Option A: Homebrew (macOS/Linux - Recommended)

```bash
brew install mcp-toolbox
```

Verify installation:
```bash
toolbox --version
```

### Option B: Download Binary

**macOS (Apple Silicon):**
```bash
export VERSION=0.18.0
curl -L -o toolbox https://storage.googleapis.com/genai-toolbox/v$VERSION/darwin/arm64/toolbox
chmod +x toolbox
sudo mv toolbox /usr/local/bin/
```

**macOS (Intel):**
```bash
export VERSION=0.18.0
curl -L -o toolbox https://storage.googleapis.com/genai-toolbox/v$VERSION/darwin/amd64/toolbox
chmod +x toolbox
sudo mv toolbox /usr/local/bin/
```

**Linux (AMD64):**
```bash
export VERSION=0.18.0
curl -L -o toolbox https://storage.googleapis.com/genai-toolbox/v$VERSION/linux/amd64/toolbox
chmod +x toolbox
sudo mv toolbox /usr/local/bin/
```

**Windows (AMD64):**
```powershell
$VERSION = "0.18.0"
Invoke-WebRequest -Uri "https://storage.googleapis.com/genai-toolbox/v$VERSION/windows/amd64/toolbox.exe" -OutFile "toolbox.exe"
```

**Note:** Check the [releases page](https://github.com/googleapis/genai-toolbox/releases) for the latest version number.

### Option C: Docker Container

```bash
export VERSION=0.18.0
docker pull us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:$VERSION
```

### Option D: Build from Source (requires Go)

```bash
go install github.com/googleapis/genai-toolbox@v0.18.0
```

---

## Part 2: Configure GCP Authentication

MCP Toolbox uses Application Default Credentials (ADC) to access BigQuery.

### Setup ADC

```bash
gcloud auth application-default login
```

This opens your browser to authenticate and stores credentials locally.

### Verify Access

Test that you can query your FOCUS view:

```bash
bq query --use_legacy_sql=false \
  'SELECT COUNT(*) as row_count FROM `YOUR_PROJECT.YOUR_DATASET.YOUR_FOCUS_VIEW` LIMIT 1'
```

Replace `YOUR_PROJECT`, `YOUR_DATASET`, and `YOUR_FOCUS_VIEW` with your actual values.

---

## Part 3: Configure MCP Tools

### 1. Edit mcp_tools.yaml

Open the `mcp_tools.yaml` file in this repository and replace these values:

```yaml
sources:
  focus-bigquery:
    kind: bigquery
    project: YOUR_PROJECT_ID        # ← Replace with your GCP project ID
    location: us                     # ← Change if your dataset is in another region
```

In **every tool statement**, replace:
```sql
FROM `YOUR_PROJECT_ID.YOUR_DATASET.YOUR_FOCUS_VIEW`
```

With your actual table path, for example:
```sql
FROM `my-billing-project.billing_exports.focus_v1_0`
```

**Quick Find & Replace:**
- Find: `YOUR_PROJECT_ID.YOUR_DATASET.YOUR_FOCUS_VIEW`
- Replace: `your-actual-project.your-actual-dataset.your-actual-view`

### 2. Validate Configuration

```bash
# Test the configuration
toolbox --tools-file mcp_tools.yaml --stdio --validate
```

This checks for syntax errors without starting the server.

**Note:** The `--stdio` flag tells toolbox to use standard input/output for the MCP protocol instead of trying to start an HTTP server. This is required for Claude Desktop integration.

---

## Part 4: Start MCP Toolbox Server

### Run the Server

```bash
toolbox --tools-file mcp_tools.yaml --stdio
```

You should see the server start and listen on stdio (standard input/output) for MCP protocol messages.

**Keep this terminal open** - the server needs to run continuously.

### Run in Background (Optional)

**macOS/Linux:**
```bash
nohup toolbox --tools-file mcp_tools.yaml --stdio > toolbox.log 2>&1 &
echo $! > toolbox.pid
```

To stop:
```bash
kill $(cat toolbox.pid)
```

**Docker:**
```bash
export VERSION=0.18.0
docker run -d \
  -v ~/.config/gcloud:/root/.config/gcloud:ro \
  -v $(pwd)/mcp_tools.yaml:/config/tools.yaml:ro \
  --name mcp-toolbox \
  us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:$VERSION \
  --tools-file /config/tools.yaml \
  --stdio
```

---

## Part 5: Test with MCP Inspector

The MCP Inspector is a web-based tool to test your MCP server.

### Install MCP Inspector

```bash
npm install -g @modelcontextprotocol/inspector
```

### Launch Inspector

```bash
mcp-inspector toolbox --tools-file mcp_tools.yaml --stdio
```

This opens a web UI at `http://localhost:3000`

### Test a Tool

1. In the Inspector UI, select a tool (e.g., `get_total_spend`)
2. Fill in parameters (e.g., `days_back: 30`)
3. Click "Execute"
4. Verify results are returned

---

## Part 6: Integrate with Claude Desktop

### 1. Locate Claude Desktop Config

**macOS:**
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

**Linux:**
```
~/.config/Claude/claude_desktop_config.json
```

### 2. Add MCP Server Configuration

Create or edit `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "focus-costs": {
      "command": "toolbox",
      "args": [
        "--tools-file",
        "/absolute/path/to/mcp_tools.yaml",
        "--stdio"
      ]
    }
  }
}
```

**Important:**
- Use absolute path to `mcp_tools.yaml`
- On Windows, use forward slashes: `C:/Users/YourName/...`

### 3. Restart Claude Desktop

Quit and reopen Claude Desktop completely.

### 4. Verify Integration

In a new Claude conversation, type:

> "What tools do you have access to?"

Claude should list your FOCUS cost tools.

### 5. Test a Query

Try asking:

> "What did we spend last month?"

Claude will use the `get_total_spend` tool and show results.

---

## Part 7: Integrate with Gemini CLI (Optional)

### Install Gemini CLI

**Option 1: Homebrew (Recommended for macOS/Linux):**
```bash
brew install gemini-cli
```

**Option 2: npm global install:**
```bash
npm install -g @google/gemini-cli
```

**Option 3: Use without installing (npx):**
```bash
npx @google/gemini-cli
```

**Requirements:** Node.js 20 or higher

Verify installation:
```bash
gemini --version
```

### Configure MCP Server

Edit `~/.gemini/settings.json` to add the MCP server:

```json
{
  "mcpServers": {
    "focus-costs": {
      "command": "toolbox",
      "args": [
        "--tools-file",
        "/absolute/path/to/mcp_tools.yaml",
        "--stdio"
      ]
    }
  }
}
```

### Test

Start Gemini CLI and ask cost questions:
```bash
gemini chat

# Then ask in the chat:
# "What are our top 5 services by cost?"
# "What did we spend last month?"
```

---

## Part 8: Use in Python Applications (Optional)

### Install SDK

```bash
pip install mcp-client
```

### Example Code

```python
from mcp import Client

# Connect to MCP server
client = Client(
    command="toolbox",
    args=["--tools-file", "/absolute/path/to/mcp_tools.yaml", "--stdio"]
)

# List available tools
tools = client.list_tools()
print(f"Available tools: {[t['name'] for t in tools]}")

# Call a tool
result = client.call_tool(
    "get_total_spend",
    parameters={"days_back": 30}
)

print(result)
```

---

## Troubleshooting

### Error: "Authentication failed"

**Solution:**
```bash
# Re-authenticate
gcloud auth application-default login

# Verify credentials
gcloud auth application-default print-access-token
```

### Error: "Table not found"

**Solution:**
- Verify your FOCUS view exists: `bq ls YOUR_PROJECT:YOUR_DATASET`
- Check table path in `mcp_tools.yaml` is correct
- Ensure you have BigQuery permissions

### Error: "No tools loaded"

**Solution:**
- Validate YAML syntax: `toolbox --tools-file mcp_tools.yaml --validate`
- Check for typos in tool definitions
- Ensure proper indentation (YAML is indent-sensitive)

### Claude Desktop doesn't see tools

**Solution:**
1. Check config file location is correct
2. Verify absolute path in config
3. Restart Claude Desktop completely (quit from menu bar)
4. Check Claude Desktop logs:
   - macOS: `~/Library/Logs/Claude/`
   - Windows: `%APPDATA%\Claude\logs\`

### Tools return "Permission denied"

**Solution:**
```bash
# Grant BigQuery permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT \
  --member="user:YOUR_EMAIL" \
  --role="roles/bigquery.dataViewer"
```

### Slow query performance

**Solution:**
- Add date filters to limit data scanned
- Consider creating materialized view for large datasets
- Check BigQuery query execution in console

---

## Advanced Configuration

### Enable OpenTelemetry Tracing

```bash
toolbox --tools-file mcp_tools.yaml \
  --stdio \
  --telemetry-endpoint http://localhost:4318
```

### Custom Port (for HTTP mode)

**Note:** For Claude Desktop, always use `--stdio` mode. HTTP mode is only for direct API access.

```bash
toolbox --tools-file mcp_tools.yaml \
  --http \
  --port 8080
```

### Dynamic Tool Reloading

Changes to `mcp_tools.yaml` are automatically reloaded by default. To disable:

```bash
toolbox --tools-file mcp_tools.yaml --stdio --no-watch
```

### Connection Pooling

MCP Toolbox automatically pools BigQuery connections. Configure limits:

```yaml
sources:
  focus-bigquery:
    kind: bigquery
    project: YOUR_PROJECT_ID
    location: us
    max_connections: 10  # Optional: default is 5
```

---

## Security Best Practices

1. **Limit Permissions**: Use least-privilege IAM roles
   ```bash
   # Grant only BigQuery Data Viewer, not Editor
   gcloud projects add-iam-policy-binding PROJECT \
     --member="user:EMAIL" \
     --role="roles/bigquery.dataViewer"
   ```

2. **Restrict Table Access**: Use BigQuery authorized views if needed

3. **Audit Logs**: Enable BigQuery audit logging
   ```bash
   gcloud logging read "resource.type=bigquery_resource"
   ```

4. **Rotate Credentials**: Refresh ADC periodically
   ```bash
   gcloud auth application-default login
   ```

5. **Version Control**: Keep `mcp_tools.yaml` in git (excludes credentials)

---

## Maintenance

### Update MCP Toolbox

**Homebrew:**
```bash
brew upgrade mcp-toolbox
```

**Binary:**
Download the latest version and replace:
```bash
export VERSION=0.18.0  # Update to latest version
curl -L -o toolbox https://storage.googleapis.com/genai-toolbox/v$VERSION/darwin/arm64/toolbox
chmod +x toolbox
sudo mv toolbox /usr/local/bin/
```

**Docker:**
```bash
export VERSION=0.18.0  # Update to latest version
docker pull us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:$VERSION
```

### Monitor Usage

Check BigQuery query costs:
```bash
bq show --project_id YOUR_PROJECT --format=json
```

### Update Tools

1. Edit `mcp_tools.yaml`
2. Save file
3. MCP Toolbox automatically reloads (if watch enabled)
4. Test changes with MCP Inspector

---

## Next Steps

1. ✅ Read `mcp_example_prompts.md` for natural language query examples
2. ✅ Review `mcp_tool_reference.md` for complete tool documentation
3. ✅ Customize tools in `mcp_tools.yaml` for your organization
4. ✅ Create additional tools from FOCUS use case queries
5. ✅ Set up automated cost alerts using Python SDK

---

## Resources

- [MCP Toolbox Documentation](https://googleapis.github.io/genai-toolbox/)
- [Model Context Protocol Spec](https://spec.modelcontextprotocol.io/)
- [FOCUS Specification](https://focus.finops.org/)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [MCP Toolbox GitHub](https://github.com/googleapis/genai-toolbox)

---

## Support

For issues:
- MCP Toolbox: [GitHub Issues](https://github.com/googleapis/genai-toolbox/issues)
- FOCUS queries: See repository README
- GCP BigQuery: [Google Cloud Support](https://cloud.google.com/support)
