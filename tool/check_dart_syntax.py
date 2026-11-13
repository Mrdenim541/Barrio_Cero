"""Syntax-only fallback when Dart SDK is unavailable; does NOT type check."""
from pathlib import Path
import tree_sitter_dart
from tree_sitter import Language, Parser
p = Parser(Language(tree_sitter_dart.language()))
errors=[]
for folder in ('lib','tool','test'):
 for f in Path(folder).rglob('*.dart'):
  tree=p.parse(f.read_bytes())
  def walk(n):
   if n.type=='ERROR' or n.is_missing:
    errors.append(f'{f}:{n.start_point.row+1}:{n.start_point.column+1}: {n.type}')
   for c in n.children:walk(c)
  walk(tree.root_node)
print('\n'.join(errors) if errors else 'Dart syntax parsed successfully (no type checking or execution).')
raise SystemExit(bool(errors))
