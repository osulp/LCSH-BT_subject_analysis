<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace=""
    exclude-result-prefixes="#all" version="2.0">
    
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="iteration" select="'unspecified'"/>
    <!-- User specify an iteration or level number  -->
    
    <xsl:variable name="output_filename" select="concat($iteration, '-2_bt_list.xml')"/>
    
    <xsl:template match="LC_lookups">

        <!-- Send output to a document -->
        <xsl:result-document href="{$output_filename}">
            <bt_list>
                
                <!-- 
                  - Rearrange the fetched broader term entries:
                        - If the BT has subdivisions, reduce to the root and remove the subdivided terms
                        - If no BTs found, mark the LC_subject heading as terminus value="true"
                        - For each BT fetched, create a broader term entry with a copy of the LC_subject heading from the previous iteration's topic model.
                  - Validate for LCSH by omitting any terms with no URI
                -->

                <xsl:for-each select="LC_subject">
                    
                    <xsl:choose>
                        <xsl:when test="not(broader_terms/term)">
                            <broader_term>
                                <xsl:copy-of select="label | occurrences | narrower_terms"/>
                                <terminus value="true"/>
                            </broader_term>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="broader_terms/term[not(uri = '')]">
                                <broader_term>
                                    <label>
                                        <xsl:value-of select="label"/>
                                    </label>
                                    <reference>
                                        <xsl:copy-of
                                            select="ancestor::LC_subject/*[not(name() = 'broader_terms')][not(name() = 'uri')]"
                                        />
                                    </reference>
                                </broader_term>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </bt_list>
        </xsl:result-document>
    </xsl:template>


</xsl:stylesheet>