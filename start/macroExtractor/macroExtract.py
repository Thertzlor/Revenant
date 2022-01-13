import xml.etree.ElementTree as tree
import os

minDelay = 100
xns = {'x':'*'}


def nextUp(index,array):
   downKey = array[index]['key']
   def upVersion(idx):
      return array[idx]['dir'] == 'up' and array[idx]['key'] == downKey

   if array[index+1] is not int and upVersion(index+1): return 1
   if array[index+1] is int and array[index+1] < minDelay and upVersion(index+2):return 2
   return False

def macroExtract(path):
   root = tree.parse(path).getroot()
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
            condensed = []
            delayBuffer = 0
            stringBuffer = ''
            i = 0
            while i < len(naiveList):
               entry= naiveList[i]
               if type(entry) is int and int > minDelay:
                  if stringBuffer != '':
                     condensed.append(stringBuffer)
                     stringBuffer= ''
                  condensed.append(int)
               else:
                  k = entry['key']
                  upNum = nextUp(i)
                  if upNum:
                     i+=upNum
                     stringBuffer

               i+=i

      elif block:
         print(mac.get('name'))
         textEl = block.find('x:text',xns)
         macDict[mac.get('name')] = {'content':textEl.text,'actionDelay':textEl.get('delay')}

   print(macDict)

[macroExtract(p) for p in os.listdir() if p.endswith('.xml')]