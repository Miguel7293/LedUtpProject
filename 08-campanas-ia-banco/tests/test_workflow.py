import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.workflow import run, validate, matching

client = TestClient(app)

def test_actual_graph_pdf_and_channels():
    result = run('demo-001')
    assert result['trace'] == ['matching','retrieve_pdf','creative','validate']
    assert [c['id'] for c in result['selected']] == ['ABC-VIA','ABC-GAS','ABC-EDU']
    assert result['status'] == 'needs_human_review'
    assert result['sources'] and all(s['page'] >= 1 and s['text'] for s in result['sources'])
    assert 'Privacidad' in ''.join(s['text'] for s in result['sources'])
    assert all(len(d['sms']) <= 160 and d['terms'] and d['source_ids'] for d in result['drafts'])
    assert 'customer' not in result

def test_different_profile_changes_matching():
    assert run('demo-002')['selected'][0]['id'] == 'ABC-EDU'

def test_consent_and_unknown():
    assert client.post('/campaigns/generate', json={'customer_id':'demo-sin-consentimiento'}).status_code == 403
    assert client.post('/campaigns/generate', json={'customer_id':'missing'}).status_code == 404

def test_azure_disabled_by_default(monkeypatch):
    monkeypatch.delenv('ENABLE_AZURE_GENERATION', raising=False)
    assert client.post('/campaigns/generate', json={'customer_id':'demo-001','mode':'azure'}).status_code == 503

def test_no_fake_fallback_on_azure_failure(monkeypatch):
    monkeypatch.setenv('ENABLE_AZURE_GENERATION','true')
    monkeypatch.delenv('AZURE_OPENAI_ENDPOINT', raising=False)
    assert client.post('/campaigns/generate', json={'customer_id':'demo-001','mode':'azure'}).status_code == 502

def test_unknown_input_rejected():
    assert client.post('/campaigns/generate', json={'customer_id':'demo-001','dni':'123'}).status_code == 422

def test_invented_campaign_rejected():
    state = run('demo-001')
    state['drafts'][0]['campaign_id'] = 'inventada'
    with pytest.raises(RuntimeError):
        validate(state)

def test_promises_and_numbers_rejected():
    state = run('demo-001')
    for draft in state['drafts']:
        for key in ('benefit','terms','source_ids'):
            draft.pop(key)
    state['drafts'][0]['body'] = 'Tienes 50% garantizado'
    with pytest.raises(RuntimeError):
        validate(state)

def test_expired_campaign_filtered():
    result = matching({'customer': {'marketing_consent':True,'interests':['viajes'],'spend':{'viajes':1}}})
    assert 'ABC-OLD' not in [c['id'] for c in result['selected']]

def test_image_document_rejected():
    state = run('demo-001')
    for draft in state['drafts']:
        for key in ('benefit','terms','source_ids'):
            draft.pop(key)
    state['drafts'][0]['image_prompt_en'] = 'A passport, no text, no logos'
    with pytest.raises(RuntimeError):
        validate(state)

def test_synthetic_demographics_affinity_and_identifier_exclusion():
    common = {'marketing_consent':True,'interests':[],'spend':{}}
    assert matching({'customer':{**common,'children_demo':2}})['selected'][0]['id'] == 'ABC-EDU'
    assert matching({'customer':{**common,'age_band':'18-24'}})['selected'][0]['id'] == 'ABC-EDU'
    assert matching({'customer':{**common,'children_demo':0,'age_band':'35-44'}})['selected'] == []
    result = run('demo-001')
    assert 'FICTICIO-001' not in str(result)
    assert 'casado' not in str(result)
