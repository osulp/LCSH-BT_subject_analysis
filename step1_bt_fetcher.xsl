<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cs="http://purl.org/vocab/changeset/schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:skosxl="http://www.w3.org/2008/05/skos-xl#" 
    exclude-result-prefixes="#all" version="2.0">
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:param name="iteration" select="'unspecified'"/><!-- User specify an iteration or level number or override from command line -->
    <xsl:param name="skosrdf_path" select="'/Volumes/Seagate/subjects.skosrdf-20230607.xml'"/><!-- User update path and filename for your local copy of LCSH SKOS/RDF XML file -->
    
    <xsl:variable name="skosrdf" select="document($skosrdf_path)"/>
    <xsl:variable name="lc_records" select="$skosrdf/rdf:RDF"/>
    <xsl:variable name="output_filename" select="concat($iteration, '-1_fetched_bts.xml')"/>
    
    <xsl:template match="topic_list">
        
        <xsl:result-document href="{$output_filename}">
            <LC_lookups>
                <xsl:for-each select="topic">
                    <xsl:variable name="label" select="label"/>
                    <xsl:variable name="lc_record" select="$skosrdf/rdf:RDF/rdf:Description[skos:changeNote][skos:prefLabel = $label]"/>
                    
                    <LC_subject>
                        <uri>
                            <xsl:value-of select="$lc_record/@rdf:about"/>
                        </uri>
                        <xsl:copy-of select="*"/>
                        <xsl:choose>
                            <xsl:when test="terminus/@value='true'"/>
                            <xsl:otherwise>
                                <broader_terms>
                                    <xsl:for-each select="$lc_record/skos:broader">
                                        <xsl:variable name="resource" select="@rdf:resource"/>
                                        <term>
                                            <uri>
                                                <xsl:value-of select="$resource"/>
                                            </uri>
                                            <label>
                                                <xsl:value-of
                                                    select="normalize-space(../../rdf:Description[@rdf:about = $resource][1]/skos:prefLabel)"
                                                />
                                            </label>
                                        </term>
                                    </xsl:for-each>
                                </broader_terms>
                            </xsl:otherwise>
                        </xsl:choose>
                    </LC_subject>
                </xsl:for-each>
            </LC_lookups>
        </xsl:result-document>
    </xsl:template>
    
</xsl:stylesheet>