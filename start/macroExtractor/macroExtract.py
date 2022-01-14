import xml.etree.ElementTree as tree
from os import listdir
from re import sub

optString1 = "\nWelcome to the Revenant Macro Extractor.\nThis utility will fetch multikey and textblock macros from all Logitech XML profiles in this folder.\n\nOptions:\n* The extractor can condense macros by ignoring small input delays.\n* The default delay threshold is 100ms, to retain all delays Set to 0.\n*\n* Delay threshold in ms [100]:"
optString2 = '* If you are using a German (or QWERTZ) keyboard the output strings will have to be adjusted.\n* By default a US keyboard is assumed.\n*\n* QWERTZ conversion [y/N]:'

minDelay = int(input(optString1) or 100)
translate = (input(optString2) or 'n').lower() == "y"

keymapUS = {"0" : "0", "1" : "1", "2" : "2", "3" : "3", "4" : "4", "5" : "5", "6" : "6", "7" : "7", "8" : "8", "9" : "9", "a" : "a", "appkey" : "/m", "b" : "b", "backslash" : "\\", "backspace" : "/b", "c" : "c", "capslock" : "/L", "comma" : ",", "d" : "d", "down" : "/d", "e" : "e", "end" : "/E", "enter" : "\r", "equal" : "=", "escape" : "/e", "f" : "f", "f1" : "/01", "f10" : "/10", "f11" : "/11", "f12" : "/12", "f13" : "/13", "f14" : "/14", "f15" : "/15", "f16" : "/16", "f17" : "/17", "f18" : "/18", "f19" : "/19", "f2" : "/02", "f20" : "/20", "f21" : "/21", "f22" : "/22", "f23" : "/23", "f24" : "/24", "f3" : "/03", "f4" : "/04", "f5" : "/05", "f6" : "/06", "f7" : "/07", "f8" : "/08", "f9" : "/09", "g" : "g", "h" : "h", "home" : "/h", "i" : "i", "insert" : "/i", "j" : "j", "k" : "k", "l" : "l", "lalt" : "/a", "lbracket" : "[", "lctrl" : "/c", "left" : "/l", "lgui" : "/w", "lshift" : "/s", "m" : "m", "minus" : "-", "n" : "n", "numlock" : "/N", "o" : "o", "p" : "p", "pagedown" : "/D", "pageup" : "/U", "pause" : "/P", "period" : ".", "printscreen" : "/p", "q" : "q", "quote" : "'", "r" : "r", "ralt" : "/A", "rbracket" : "]", "rctrl" : "/C", "rgui" : "/W", "right" : "/r", "rshift" : "/S", "s" : "s", "semicolon" : ";", "slash" : "//", "spacebar" : " ", "t" : "t", "tab" : "\t", "tilde" : "`", "u" : "u", "up" : "/u", "v" : "v", "w" : "w", "x" : "x", "y" : "y", "z" : "z" }
keymapQWERTZ = {"\\" : "/#", "[":"ü", "-":"ß","non_us_slash":"<","'":"ä","]":"+",";":"ö","//":"-","y":"z","z":"y"}
mods = {'/s':'~','/c':'*','/a':'#', '|':'/w'}
xns = {'x':'*'}

capitalizer = lambda a : sub(r'(?<!(?:#|\*))~([a-z])',lambda match:match.group(1).upper(),a)

def stringify(key):
   shortKey = keymapUS.get(key) or key
   if translate: shortKey = keymapQWERTZ.get(shortKey) or shortKey
   return shortKey

def nextUp(index,arr,manKey=0):
   if index + 1 == len(arr):return False 
   downKey = manKey or arr[index]['key']
   def upVersion(idx):
      return arr[idx]['dir'] == 'up' and arr[idx]['key'] == downKey

   if type(arr[index+1]) is not int and upVersion(index+1): return 1
   if type(arr[index+1]) is int and arr[index+1] < minDelay and upVersion(index+2):return 2
   return False

def wrapping(index,arr):
   if index + 1 == len(arr):return False 
   downKey=arr[index]['key']
   nextInt = type(arr[index+1]) is int
   if nextInt and arr[index+1] > minDelay: return False
   buffer = 1 if nextInt else 0
   upVal = nextUp(index+buffer+1,arr)
   if not upVal:return False
   selfUp = nextUp(index+buffer+upVal+1,arr,downKey)
   if not selfUp:return False
   return [buffer+upVal+selfUp+1,arr[index+1+buffer]['key']]

def macroExtract(path):
   root = tree.parse(path).getroot()
   macList = []
   profile = root.find('x:profile',xns)
   profileName = profile.get('name')
   print('Processing profile "'+profileName+'"')
   macros = profile.find('x:macros',xns).findall('x:macro',xns)
   for mac in macros:
      block = mac.find('x:textblock',xns)
      mult = mac.find('x:multikey',xns)
      macName = ''
      if mult or block: macName = mac.get('name')
      if mult:
         naiveList = [ int(el.get('milliseconds')) if el.tag.endswith('delay') else {'key':el.get('value').lower(),'dir':el.get('direction')} for el in mult]
         if len(naiveList) != 1 or naiveList[0] != 0:
            print('- Extracting MultiKey macro "'+macName+'"')
            condensed = []
            stringBuffer = ''
            i = 0
            while i < len(naiveList):
               entry= naiveList[i]
               if type(entry) is int and entry > minDelay:
                  if stringBuffer != '':
                     condensed.append(capitalizer('"'+stringBuffer+'"'))
                     stringBuffer= ''
                  condensed.append(str(entry))
               elif type(entry) is not int:
                  k = entry['key']
                  upNum = nextUp(i,naiveList) if entry['dir'] == "down" else 0
                  isMod = (not upNum) and mods.get(stringify(k))
                  wraps = isMod and wrapping(i,naiveList)
                  if upNum:
                     i+=upNum
                     stringBuffer += stringify(k)
                  elif wraps:
                     i+=wraps[0]
                     stringBuffer += isMod+stringify(wraps[1])
                  else:
                     if stringBuffer != '':
                        condensed.append(capitalizer('"'+stringBuffer+'"'))
                        stringBuffer= ''
                     condensed.append('{"'+stringify(k)+'", t="'+("u" if entry["dir"]=="up" else "d")+'"}')
               i+=1
            if stringBuffer != '':condensed.append(capitalizer('"'+stringBuffer+'"'))
            macObj = {'content':', '.join(condensed), 'name':macName}

            macObj['actionDelay'] = mac.get('repeatdelay')
            macObj['play'] = 'hold' if mac.get('repeatmode') == "pressed" else mac.get('repeatmode')
            macList.append(macObj)

      elif block:
         print('- Extracting TextBlock macro "'+macName+'"')
         textEl = block.find('x:text',xns)
         macObj={'content':'"'+textEl.text+'"','name':macName}
         macObj['actionDelay'] = textEl.get('delay')
         macList.append(macObj)

   endFile = profileName+'_macros.txt'
   with open('./'+endFile,"w") as r:
      r.write('\n\n'.join(['{ '+m['content']+(', ad='+m['actionDelay'] if m.get('actionDelay') else '')+(', play="'+m["play"]+'"' if m.get('play') else '')+', t="s", name="'+m['name']+'" }' for m in macList]))
      print("\nSaved results in "+endFile+'\n')

print('\nStarting extraction.\n')
[macroExtract(p) for p in listdir() if p.endswith('.xml')]