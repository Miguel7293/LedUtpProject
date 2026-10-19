"""One real paid generation. Requires Azure CLI sign-in and explicit configuration."""
import json
from pathlib import Path
from app.workflow import run

result = run('demo-001', 'azure')
assert result['status'] == 'needs_human_review'
assert len(result['drafts']) == 3
assert result['usage'].get('total_tokens', 0) > 0
out = Path('.local/azure-generation.json')
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'status': result['status'], 'campaigns': len(result['drafts']), 'usage': result['usage']}, ensure_ascii=False))
