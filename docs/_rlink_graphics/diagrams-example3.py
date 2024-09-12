from diagrams import Diagram, Cluster, Edge
from diagrams.custom import Custom

with Diagram('Hello, World.',
             outformat='png',
             filename='example3',
             direction='LR',
             show=True):
  cc_heart = Custom('Creative Commons', './resources/ccheart_black.png')
  cc_attribution = Custom('Credit must be given to the creator', './resources/by.png')

  cc_sa = Custom('Adaptations must be shared\n under the same terms', './resources/sa.png')
  cc_nd = Custom('No derivatives or adaptations\n of the work are permitted', './resources/nd.png')
  cc_zero = Custom('Public Domain Dedication', './resources/zero.png')

  with Cluster('Non Commercial'):
    non_commercial = [
        Custom('Y', './resources/nc-jp.png') - Custom('E', './resources/nc-eu.png') - Custom('S', './resources/nc.png')
    ]

#  cc_heart >> Edge(color='darkgreen', label='Foobar', style='odiamond') >> cc_attribution
#  cc_heart >> Edge(style='diamond') >> cc_attribution
  cc_heart >> Edge(style='dashed', dir='both', arrowhead='diamond') >> cc_attribution
  cc_heart >> non_commercial
  cc_heart >> cc_sa
  cc_heart >> cc_nd
  cc_heart >> cc_zero
