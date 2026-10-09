"""Adds files in jpex/ to the jpex target (Swift to Sources, JSON to Resources), skipping ones
already there. Usage: python3 add_to_project.py jpex/Foo.swift jpex/Maps/geo_X.json ..."""
import hashlib, re, sys

PBX = 'jpex.xcodeproj/project.pbxproj'
GROUP_ANCHOR = '466A25279D4D746BC8B62EB5 /* GameSpotlight.swift */,'
SOURCES = '45F6B69A2B63D05A00931EEB /* Sources */ = {'
RESOURCES = '45F6B69C2B63D05A00931EEB /* Resources */ = {'

def uid(seed):
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()

text = open(PBX).read()
for path in sys.argv[1:]:
    rel = path[len('jpex/'):] if path.startswith('jpex/') else path
    name = rel.split('/')[-1]
    if re.search(r'path = %s;' % re.escape(rel), text) or re.search(r'path = "%s";' % re.escape(rel), text):
        print('already in project:', rel); continue
    is_swift = name.endswith('.swift')
    ftype = 'sourcecode.swift' if is_swift else 'text.json'
    phase = 'Sources' if is_swift else 'Resources'
    ref, build = uid('ref-' + rel), uid('build-' + rel)
    text = text.replace('/* Begin PBXBuildFile section */\n',
        '/* Begin PBXBuildFile section */\n\t\t%s /* %s in %s */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };\n' % (build, name, phase, ref, name), 1)
    text = text.replace('/* Begin PBXFileReference section */\n',
        '/* Begin PBXFileReference section */\n\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = %s; path = %s; sourceTree = "<group>"; };\n' % (ref, name, ftype, rel), 1)
    assert GROUP_ANCHOR in text
    text = text.replace(GROUP_ANCHOR, GROUP_ANCHOR + '\n\t\t\t\t%s /* %s */,' % (ref, name), 1)
    anchor = SOURCES if is_swift else RESOURCES
    start = text.index(anchor)
    files = text.index('files = (\n', start) + len('files = (\n')
    text = text[:files] + '\t\t\t\t%s /* %s in %s */,\n' % (build, name, phase) + text[files:]
    print('added', rel)
open(PBX, 'w').write(text)
