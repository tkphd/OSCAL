<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:oscal="http://scap.nist.gov/schema/oscal"
  version="1.0">
  
  <xsl:import href="oscal-basic-display.xsl"/>
  
  <xsl:template match="oscal:call">
    <xsl:variable name="catalog" select="document(ancestor::oscal:invoke/@href,/)"/>
    <xsl:apply-templates select="$catalog//oscal:control | $catalog//oscal:subcontrol" mode="display">
      <xsl:with-param name="caller" select="."/>
    </xsl:apply-templates>
    
  </xsl:template>
    
    
    
      
</xsl:stylesheet>