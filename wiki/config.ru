
require 'utopia/setup'
UTOPIA ||= Utopia.setup

require 'utopia/wiki'

Utopia::Wiki.call(self,
# If you want to localize your wiki, specify the languages:
#	locales: ['en', 'ja']
)
