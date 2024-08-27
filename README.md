# LCSH Broader Terms Subject Analysis

This repository contains several XSLT 2.0 stylesheets run in sequence against a local copy of the Library of Congress Subject Headings in SKOS RDF format. The pipeline constructs a model of progressively broader subject headings for a given collection of library materials based on the LC subject terms found in the collection's metadata records (e.g. MARC catalog records, EAD finding aids, Dublin Core records, etc.). The repository includes tools to analyze and present the resulting model. 

## Background and development

This method was developed to create a baseline topic model for a research article _Text analysis of archival finding aids_, which is pending publication in _Information Technology and Libraries_ as of August 2024. The final topic model produced for that project using this method is contained in the supplementary OSF repository: 

> Bahde, A. & Key, C. (2024b). Text analysis of archival finding aids: Supporting materials [Dataset]. Open Science Framework. http://doi.org/10.17605/OSF.IO/AUXF4

## Requirements and setup

- Requires an XSLT 2.0 processor. Can be run with an application such as oXygen but a command line tool is recommended. Commands are given below using Saxon; see https://www.saxonica.com/.
- Requires a local copy of Library of Congress Subject Headings (LCSH) serialized as SKOS/RDF XML, which can be obtained from LC's Linked Data Service Bulk Downloads page at https://id.loc.gov/download/.
  - In order to use the LCSH file as valid XML, the repeated XML declaration and the `rdf:RDF` wrapper element must be stripped from individual authority records, keeping them only at the top/root level of the XML file. This can be achieved by various techniques; the author used the find/replace function in a text editor. 
- Requires a source collection of digital metadata records ... 
  
## Usage

_Examples are derived from Oregon State University's Special Collections and Archives Research Center's public collection of finding aids, from the project mentioned above._


## Planned improvements

This pipeline is admittedly cumbersome. This is due in part to the author's limitations, but also to the processing demands of parsing the entirety of LCSH. Future dedicated research into LCSH topic modeling is planned, which will include simplifying and streamlining this pipeline.
