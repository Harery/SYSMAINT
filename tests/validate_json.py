#!/usr/bin/env python3
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery
import json, sys, os
try:
    import jsonschema
except ImportError:
    print("ERROR: jsonschema not installed. Run: pip install jsonschema", file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 3:
    print("Usage: validate_json.py <schema.json> <summary.json>", file=sys.stderr)
    sys.exit(2)

schema_path, json_path = sys.argv[1], sys.argv[2]
with open(schema_path, 'r') as f:
    schema = json.load(f)
with open(json_path, 'r') as f:
    data = json.load(f)

try:
    jsonschema.validate(instance=data, schema=schema)
    print("JSON schema validation: OK")
    sys.exit(0)
except jsonschema.exceptions.ValidationError as e:
    print("JSON schema validation FAILED:", e.message, file=sys.stderr)
    sys.exit(1)
