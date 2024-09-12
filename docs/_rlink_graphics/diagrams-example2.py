# source: https://diagrams.mingrammer.com/docs/nodes/custom#custom-with-local-icons
# icons: https://creativecommons.org/about/downloads/

# to build, run from root folder:
#
#   python docs/_rlink_graphics/diagrams-example2.py
#   firefox docs/_graphics/diagrams-example2.svg

from diagrams import Diagram, Cluster
from diagrams.custom import Custom

OUTFORMAT = 'png'
# RESOURCE_DIR = 'docs/_rlink_graphics/resources/'
RESOURCE_DIR = './resources/'

with Diagram("Custom with local icons\n Can be downloaded here: \nhttps://creativecommons.org/about/downloads/",
             outformat=OUTFORMAT,
             filename="docs/_graphics/diagrams-example2",
             direction="LR",
             show=True):
  cc_heart = Custom("Creative Commons", RESOURCE_DIR + "ccheart_black." + OUTFORMAT)
  cc_attribution = Custom("Credit must be given to the creator", RESOURCE_DIR + "by." + OUTFORMAT)

  cc_sa = Custom("Adaptations must be shared\n under the same terms", RESOURCE_DIR + "sa." + OUTFORMAT)
  cc_nd = Custom("No derivatives or adaptations\n of the work are permitted", RESOURCE_DIR + "nd." + OUTFORMAT)
  cc_zero = Custom("Public Domain Dedication", RESOURCE_DIR + "zero." + OUTFORMAT)

  with Cluster("Non Commercial"):
    non_commercial = [Custom("Y", RESOURCE_DIR + "nc-jp." + OUTFORMAT) - Custom("E", RESOURCE_DIR + "nc-eu." + OUTFORMAT) - Custom("S", RESOURCE_DIR + "nc." + OUTFORMAT)]

  cc_heart >> cc_attribution
  cc_heart >> non_commercial
  cc_heart >> cc_sa
  cc_heart >> cc_nd
  cc_heart >> cc_zero
