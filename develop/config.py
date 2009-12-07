import yaml,os

INICONFIG ='config.yaml'

testdict = {'infoFields':('firstname','lastname','organization'),'nestdict':{'name':'mockname','email':'mockmail'}}
stream = open(INICONFIG, 'wb')
yaml.dump(testdict, stream)
#stream.flush()
stream.close()
stream = open(INICONFIG, 'rb')
config = yaml.load(stream)
stream.close()
request=this.cwd