require "sandy/area"
require "httparty"
require "json"

module Sandy::Provider
  module ConEd
    class Report
      attr_reader :regions, :neighborhoods

      def initialize
        raw_report = JSON.parse(HTTParty.get(coned_url))
        area_hash = raw_report.fetch("file_data")["curr_custs_aff"]["areas"].first["areas"]
        @regions = regions_from_report(area_hash)
        @neighborhoods = neighborhoods_from_report(area_hash)
      end

      private

      def regions_from_report(areas)
        areas.collect do |area|
          Sandy::Area.new(area.fetch("custs_out"), area.fetch("area_name"),
                          { latitude: area["latitude"], longitude: area["longitude"] })

        end
      end

      def neighborhoods_from_report(areas)
        areas.collect do |area|
          area["areas"].each do |sub_area|
            Sandy::Area.new(sub_area.fetch("custs_out"), sub_area.fetch("area_name"),
                            { region: area["area_name"], 
                              latitude: sub_area["latitude"], 
                              longitude: sub_area["longitude"] })
          end
        end
      end

      def coned_url
        base_uri = "http://apps.coned.com"
        directory_url = "#{base_uri}/stormcenter_external/stormcenter_externaldata/data/interval_generation_data/metadata.xml"
        response = HTTParty.get(directory_url, format: :xml)
        directory = response.parsed_response.fetch("root").fetch("directory")
        "#{base_uri}/stormcenter_external/stormcenter_externaldata/data/interval_generation_data/#{directory}/report.js"
      end
    end
  end
end
