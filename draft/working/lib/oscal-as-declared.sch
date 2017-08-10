<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <sch:ns uri="http://scap.nist.gov/schema/oscal" prefix="oscal"/>
  
  <xsl:include href="oscal-functions.xsl"/>
   
  
<!-- Declarations are the contents of local declarations, if present, or the document at href if locally empty.  -->
  <sch:let name="declarations"
    value="/oscal:catalog/ ( oscal:declarations[empty(@href)], oscal:declarations/document(@href,/)/oscal:declarations )[1]"/>
  
  <sch:pattern>
    <sch:rule context="oscal:catalog">
      <sch:assert test="exists($declarations)" role="warning">No declarations found (properties will not be checked).</sch:assert>
      
      <!--<sch:report test="true()"><sch:value-of select="oscal:sequence($declarations/*/local-name())"/></sch:report>-->
      
    </sch:rule>
    
    <!--  Constraints over declarations - very important!  -->
    <sch:rule context="oscal:property | oscal:statement | oscal:parameter | oscal:feature">
      <sch:let name="me" value="."/>
      <!-- oscal:declares returns a set of strings indicating classes and context to which declarations are bound -->
      <sch:let name="look-the-same" value="
        ../(* except $me)[oscal:signatures(.) = oscal:signatures($me)]"/>
      <sch:assert test="empty($look-the-same)">Declaration clashes with another declaration.</sch:assert>
      <!--<sch:report test="true()"><sch:value-of select="oscal:sequence(oscal:signatures(.))"/></sch:report>-->
    </sch:rule>
  
    <!-- Constraints over groups, controls and enhancements (subcontrols, features)
         regarding required properties and statements
         (not yet parameters) -->
    <sch:rule context="oscal:group | oscal:control | oscal:subcontrol | oscal:feat">
      <xsl:variable name="this" select="."/>
      <xsl:variable name="matches"  select="oscal:classes($this),local-name($this)"/>
      <sch:let name="applicable" value="$declarations/key('declarations-by-context',$matches,$declarations)"/>
      
      <!--<sch:report test="true()" role="warning"><sch:value-of select="oscal:sequence($matches)"/> 
      
        <sch:value-of select="oscal:sequence($declarations/*/@context)"/>
      </sch:report>-->
      
      <sch:assert role="warning" test="exists($applicable) or empty((oscal:param|oscal:prop|oscal:stmt|oscal:feat)/@class)">No declarations apply to this <sch:name/></sch:assert>
      
      <!-- First properties (prop) then statements (stmt) -->
      <!-- Finding property declarations for required properties.  -->
      <sch:let name="required-property-declarations" value="$applicable/self::oscal:property[exists(oscal:required)]"/>
      <sch:let name="required-property-classes" value="$required-property-declarations/oscal:classes(.)"/>
      <!-- Identifying the classes of those that are not found among children -->
      <sch:let name="missing-property-classes" value="$required-property-classes[not(. = $this/child::*/oscal:classes(.))]"/>
      
      <sch:assert test="empty($missing-property-classes)">Required 
        <xsl:value-of select="if (count($missing-property-classes) gt 1) then 'properties are ' else 'property is'"/>
        missing: expecting <xsl:value-of select="oscal:sequence($missing-property-classes)"/>
        on <sch:name/> <sch:value-of select="oscal:sequence(oscal:classes($this) )"/></sch:assert>
      
      <sch:let name="required-statement-declarations" value="$applicable/self::oscal:statement[exists(oscal:required)]"/>
      <sch:let name="required-statement-classes" value="$required-statement-declarations/oscal:classes(.)"/>
      
      <!-- Extend to support named statements e.g. <observations> not just stmt[@class] ? -->
      <sch:let name="missing-statement-classes" value="$required-statement-classes[not(. = $this/child::*/oscal:classes(.)) ]"/>
      <sch:assert test="empty($missing-statement-classes)">Required 
        <xsl:value-of select="if (count($missing-statement-classes) gt 1) then 'statements are ' else 'statement is'"/>
        missing: expecting <xsl:value-of select="oscal:sequence($missing-statement-classes)"/>
        on <sch:name/> <sch:value-of select="oscal:sequence(oscal:classes($this) )"/>
      </sch:assert>
    </sch:rule>
   </sch:pattern>
  
  
  
<!-- Next, validating the values inside controls and control objects against matching declarations -->
  <sch:pattern>
    <sch:rule context="oscal:p | oscal:ul | oscal:ol | oscal:pre">
      <!--To do: find a way to declare controls as (not) permissive of this stuff ?-->
    </sch:rule>
    
    
    
    <!-- Exempted from declaration rules; other children of control, group, enhancement must be declared
         and will match the next rule. -->
    <!-- Note that we have no mechanism for declaring (and constraining) controls, subcontrols or groups,
         but we are expected to declare features. -->
    <sch:rule context="oscal:stmt[empty(@class)] | oscal:param | oscal:title |
      oscal:group | oscal:control | oscal:subcontrol | oscal:link | oscal:references"/>

    <sch:rule context="oscal:control/* | oscal:group/* | oscal:subcontrol/* | oscal:feat/*">
      <xsl:variable name="this" select="."/>
      

      <sch:let name="signatures" value="
        for $cx in ($this/../(oscal:classes(.),local-name(.)) ),
            $cl in (oscal:classes($this)) return string-join(($cx,$cl),'/')"/>
      
      <!-- Only properties, statements and parameters with roles must also be declared;
           other declarations come for free. -->
      <sch:let name="matching-declarations" value="$declarations/key('declarations-by-signature',$signatures,.)"/>
      
      <!--<sch:report test="true()" role="info">Seeing <sch:value-of select="count($matching-declarations)"/> matching declarations <xsl:value-of select="string-join($matching-declarations/name(),', ')"/> </sch:report>-->
      
      <sch:assert test="empty($matching-declarations) or count($matching-declarations)=1">More than one matching declaration found for <sch:name/> (signatures <sch:value-of select="oscal:sequence($signatures)"/>)
      </sch:assert>
      <sch:assert test="empty($declarations/*) or exists($matching-declarations)">No declaration found for <sch:name/> <sch:value-of select="oscal:sequence(oscal:classes(.))"/> in this location</sch:assert>
      
      <sch:let name="regex-requirements" value="$matching-declarations/oscal:regex"/>
      <!--<sch:report test="true()" role="warning"><sch:value-of select="oscal:sequence($regex-requirements)"/></sch:report>-->
      <sch:assert test="empty($regex-requirements) or (every $r in ($regex-requirements) satisfies matches(.,$r))">
        Value of property '<sch:value-of select="oscal:classes(.)"/>' is expected to match regex
        <xsl:value-of select="if (count($regex-requirements) gt 1) then '(one of) regexes' else 'regex'"/>
        <xsl:value-of select="oscal:sequence($regex-requirements)"/>'</sch:assert>
      
      <sch:let name="singleton-requirement" value="$matching-declarations/oscal:singleton"/>
      <sch:let name="single-classes" value="$singleton-requirement/oscal:classes(..)[.=oscal:classes($this)]"/>
      <sch:let name="competitors" value="$this/../*[oscal:classes(.)=$single-classes]"/>
     
      <sch:assert test="empty($singleton-requirement) or empty($competitors except $this)">
        Value of property (<sch:value-of select="oscal:sequence($single-classes)"/>) is expected to be unique to this property (instance) within the document.</sch:assert>
      
      <sch:let name="id-requirements" value="$matching-declarations/oscal:identifier"/>
      <sch:let name="id-classes" value="$id-requirements/oscal:classes(..)[.=oscal:classes($this)]"/>
      <sch:let name="cohort" value="key('prop-by-value',normalize-space($this))[oscal:classes(.)=$id-classes]"/>
      
      <sch:assert test="empty($id-requirements) or empty($cohort except $this)">
        Value of property (<sch:value-of select="oscal:sequence($id-classes)"/>) is expected to be unique to this property (instance) within the document.</sch:assert>
      
      <sch:let name="value-requirements" value="$matching-declarations/oscal:value"/>
      <sch:let name="value-classes" value="$value-requirements/oscal:classes(..)[.=oscal:classes($this)]"/>
      <xsl:variable name="resolved-values" as="element()*">
        <xsl:apply-templates select="$value-requirements" mode="expand-values">
          <!-- we pass $me as the who-cares -->
          <xsl:with-param tunnel="yes" name="who-cares" select="$this"/>
        </xsl:apply-templates>
      </xsl:variable>
      <sch:assert test="empty($value-requirements) or (. = $resolved-values)">
        Value of property <sch:value-of select="oscal:sequence(distinct-values($value-classes))"/> is expected to be 
        <xsl:value-of select="if (count($resolved-values) gt 1) then 'one of ' else ''"/>
        <xsl:value-of select="$resolved-values/concat('''',.,'''')" separator=", "/></sch:assert>
      
      
    </sch:rule>
    
  </sch:pattern>
 
 <xsl:key name="prop-by-value" match="oscal:prop" use="normalize-space(.)"/>
  
  
  
  <!--<xsl:variable name="source" select="/"/>
  
  -->
  
  <!--use="tokenize(normalize-space(lower-case(@context)),'\s')"-->
  <!-- For any control, groups or enhancement we may need (all) the declarations, as indicated by @context. -->
 
  <xsl:key name="declarations-by-context" match="oscal:declarations/*" use="tokenize(normalize-space(lower-case(@context)),'\s')"/>
  
  
<!-- Each declaration has multiple signatures, a function of its class(es) and context(s).
     Note that both can be overloaded (not that that is a good idea)
     although clashing signatures provoke errors. -->
  <!-- We use this to retrieve the particular declarations that (may) apply to any
       given property or statement. -->
  <xsl:key name="declarations-by-signature" match="oscal:declarations/*" use="oscal:signatures(.)"/>
  
   
  <xsl:function name="oscal:signatures" as="xs:string*">
    <xsl:param name="d" as="element()"/>
    <!-- delivers a sequence of strings for a declaration indicating the
         signature values 
      declarations may have multiple classes and multiple contexts (nominal parent classes) indicated by @context -->
    <xsl:for-each select="tokenize($d/@context/normalize-space(lower-case(.)),'&#32;')">
      <xsl:variable name="context" select="."/>
      <xsl:for-each select="oscal:classes($d)">
      <xsl:value-of select="string-join(($context,.),'/')"/>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:function>
  
  <xsl:template match="oscal:value" mode="expand-values">
    <xsl:variable name="expanded">
      <xsl:apply-templates mode="expand-values"/>
    </xsl:variable>
    <xsl:copy><xsl:value-of select="normalize-space($expanded)"/></xsl:copy>
  </xsl:template>

  <xsl:template match="oscal:inherit" mode="expand-values">
    <xsl:param name="who-cares" required="yes" tunnel="yes"/>
    <xsl:variable name="named-classes" select="tokenize(@from/normalize-space(string(.)),'\s')"/>
    <xsl:variable name="matching-classes" select="if (empty($named-classes))
      then parent::oscal:value/parent::oscal:property/oscal:classes(.) else $named-classes"/>
    
    <xsl:variable name="forebear"
      select="$who-cares/../ancestor::*[oscal:prop/oscal:classes(.)=$matching-classes][1]/
                oscal:prop[oscal:classes(.)=$matching-classes]"/>
    <xsl:value-of select="normalize-space($forebear)"/>
    <xsl:if test="empty($forebear)">[RESOLUTIONFAIL]</xsl:if>
  </xsl:template>

  <xsl:template match="oscal:autonum" mode="expand-values">
    <xsl:param name="who-cares" required="yes" tunnel="yes"/>
    <xsl:param name="call" select="."/>
    <xsl:variable name="expanded">
      <!-- single level numbering of element among its siblings of the same name. -->
      <xsl:for-each select="$who-cares/..">
        <xsl:variable name="among" select="oscal:classes(.)"/>
        <xsl:number format="{($call/string(.),'A')[1]}" count="*[oscal:classes(.)=$among]"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="normalize-space($expanded)"/>
  </xsl:template>
  
</sch:schema>