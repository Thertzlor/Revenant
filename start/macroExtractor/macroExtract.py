import xml.etree.ElementTree as tree
import os

def macroExtract(path):
   root = tree.parse(path).getroot()
   xns = {'x':'*'}
   macDict = {}
   profile = root.find('x:profile',xns)
   profileName = profile.get('name')
   macros = profile.find('x:macros',xns).findall('x:macro',xns)
   for mac in macros:
      block = mac.find('x:textblock',xns)
      mult = mac.find('x:multikey',xns)
      if mult:
         naiveList = [ int(el.get('milliseconds')) if el.tag.endswith('delay') else {'key':el.get('value').lower(),'dir':el.get('direction')} for el in mult]
         if len(naiveList) != 1 or naiveList[0] != 0:
            print(naiveList)
      elif block:
         print(mac.get('name'))
         textEl = block.find('x:text',xns)
         macDict[mac.get('name')] = {'content':textEl.text,'actionDelay':textEl.get('delay')}

   print(macDict)

[macroExtract(p) for p in os.listdir() if p.endswith('.xml')]