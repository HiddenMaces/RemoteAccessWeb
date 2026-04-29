from flask import Flask, jsonify, request
import json, os, uuid

app = Flask(__name__)
DATA_FILE = os.getenv('DATA_FILE', '/data/links.json')

DEFAULT_DATA = {
    "settings": {"title": "Operational Gateway", "email": ""},
    "links": []
}


def load():
    if not os.path.exists(DATA_FILE):
        return {k: list(v) if isinstance(v, list) else dict(v) for k, v in DEFAULT_DATA.items()}
    with open(DATA_FILE) as f:
        return json.load(f)


def save(data):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f, indent=2)


@app.route('/api/links', methods=['GET'])
def get_all():
    return jsonify(load())


@app.route('/api/links', methods=['POST'])
def create():
    data = load()
    link = request.get_json(force=True)
    link['id'] = str(uuid.uuid4())
    data['links'].append(link)
    save(data)
    return jsonify(link), 201


@app.route('/api/links/reorder', methods=['POST'])
def reorder():
    data = load()
    ids = request.get_json(force=True).get('ids', [])
    by_id = {l['id']: l for l in data['links']}
    data['links'] = [by_id[i] for i in ids if i in by_id]
    save(data)
    return jsonify({'ok': True})


@app.route('/api/links/<lid>', methods=['PUT'])
def update(lid):
    data = load()
    for i, link in enumerate(data['links']):
        if link['id'] == lid:
            data['links'][i] = {**link, **request.get_json(force=True), 'id': lid}
            save(data)
            return jsonify(data['links'][i])
    return jsonify({'error': 'not found'}), 404


@app.route('/api/links/<lid>', methods=['DELETE'])
def delete(lid):
    data = load()
    data['links'] = [l for l in data['links'] if l['id'] != lid]
    save(data)
    return '', 204


@app.route('/api/settings', methods=['GET'])
def get_settings():
    return jsonify(load().get('settings', {}))


@app.route('/api/settings', methods=['PUT'])
def update_settings():
    data = load()
    data['settings'] = {**data.get('settings', {}), **request.get_json(force=True)}
    save(data)
    return jsonify(data['settings'])


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
