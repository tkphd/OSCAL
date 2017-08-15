<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://scap.nist.gov/schema/oscal"
  xmlns:oscal="http://scap.nist.gov/schema/oscal"
  xpath-default-namespace="http://scap.nist.gov/schema/oscal"
  exclude-result-prefixes="#all"
  version="2.0">
  
  
  <xsl:import href="oscal-functions.xsl"/>
  
  <xsl:strip-space elements="group control subcontrol feat stmt div"/>
  
  <xsl:output indent="yes"/>
  
  <xsl:variable name="source" select="/"/>
  
  <xsl:variable name="selected-controls">
    <!-- controls and subcontrols -->
    <xsl:apply-templates select="/profile/invoke" mode="select-controls"/>
  </xsl:variable>
  
  <xsl:template match="invoke" mode="select-controls">
    <xsl:variable name="invocation" select="."/>
    <xsl:variable name="catalog" select="document(@href,$source)"/>
   
    <xsl:apply-templates select="$catalog" mode="filter-controls">
      <xsl:with-param name="invocation" tunnel="yes" select="."/>
    </xsl:apply-templates>
    
  </xsl:template>
  
  <xsl:template match="/">
<!-- For now, we simply report the selected controls, without running them
     through any modifier filters. -->
    <xsl:sequence select="$selected-controls"/>
  </xsl:template>
  
  <xsl:template match="node() | @*" mode="filter-controls copy">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="node() | @*" mode="keeping">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="control | subcontrol" mode="keeping">
    <xsl:apply-templates select="." mode="filter-controls"/>
  </xsl:template>
  
  <xsl:template match="group" mode="filtering">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*" mode="filtering"/>
  
  <xsl:template match="title | prop[oscal:classes(.)='number']" mode="filtering">
    <xsl:apply-templates select="." mode="copy"/>
  </xsl:template>
  
  <xsl:template match="prop" mode="filtering">
    <xsl:param name="invocation" tunnel="yes" as="element(invoke)"/>
    <xsl:variable name="me" select="."/>
    <xsl:if test="$invocation/(include|exclude)/*/@key=oscal:classes($me)">
      <xsl:apply-templates select="." mode="copy"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="control | subcontrol" mode="filtering">
    <xsl:apply-templates select="." mode="filter-controls"/>
  </xsl:template>
  
  
  <xsl:template match="control | subcontrol" mode="filter-controls">
    <xsl:param name="invocation" tunnel="yes" as="element(invoke)"/>
    <xsl:variable name="this" select="."/>
    <xsl:variable name="properties" select="descendant::prop except descendant::subcontrol//prop"/>
    
    <xsl:variable name="filtered-results">
      <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates mode="keeping"/>
      </xsl:copy>
    </xsl:variable>
   
   <xsl:variable name="included-results">
      <xsl:choose>
        <!-- included for free when doesn't say otherwise -->
        <xsl:when test="empty($invocation/include) or exists($invocation/include/all)">
          <xsl:sequence select="$filtered-results"/>
        </xsl:when>
        <!-- included if called explicitly, oneself or an ancestor -->
        <xsl:when test="some $c in ($invocation/include/call) satisfies
              $c = $this/ancestor-or-self::*/prop[oscal:classes(.) = $c/@key]/normalize-space(.)">
          <xsl:sequence select="$filtered-results"/>
        </xsl:when>
        <!-- A 'flag' can be thrown for any contents at any level -->
        <xsl:when test="some $c in ($invocation/include/flag) satisfies
              $c = $this//prop[oscal:classes(.) = $c/@key]/normalize-space(.)">
          <xsl:sequence select="$filtered-results"/>
        </xsl:when>
        <!-- like flag, filter can include an element by virtue of a property on itself or a descendant
           except it excludes subcontrols -->
        <xsl:when test="some $c in ($invocation/include/filter) satisfies
              $c = $properties[oscal:classes(.) = $c/@key]/normalize-space(.)">
          <xsl:sequence select="$filtered-results"/>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
  </xsl:variable>
    
    
    <!-- Addressing three situations: the control or subcontrol is included; or
             it is not included; or it is suppressed. In all three cases we retain
             the bare-bones structure; 'suppression' means excluding contents -->
      
<!-- goes true() if the matching control or subcontrol, or an ancestor, was excluded.   -->
    <xsl:variable name="excluded-by-call" as="xs:boolean" select="some $c in ($invocation/exclude/call) satisfies
      $c = $this/ancestor-or-self::*/prop[oscal:classes(.)=$c/@key]/normalize-space(.)"/>
    
    <xsl:choose>
      <xsl:when test="$excluded-by-call">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:apply-templates select="title | prop" mode="filtering"/>
          <prop class="profile_trace">[EXCLUDED]</prop>
        </xsl:copy>
      </xsl:when>
      <!-- $included-results is empty if we weren't included -->
      <xsl:when test="empty($included-results/*)">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:apply-templates select="title | prop" mode="filtering"/>
          <prop class="profile_trace">[NOT INCLUDED]</prop>
          <!-- In this case we nonetheless recurse in mode filter-controls in case we have more subcontrols to filter -->
          <!-- (but we don't pick up and handle any children either) -->
          <xsl:apply-templates select="group | subcontrol" mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$included-results"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  
  
 
  <xsl:template match="group" mode="filter-controls">
    <xsl:copy>
    <xsl:apply-templates select="@*" mode="#current"/>
    <xsl:apply-templates select="title" mode="#current"/>
   
    <xsl:apply-templates select="group | control | subcontrol" mode="#current"/>
  </xsl:copy>
  </xsl:template>
  
  
</xsl:stylesheet>