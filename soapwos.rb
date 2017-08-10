require 'savon'
require 'pp'

class SoapWOS
  def initialize(opts={})
    @client       = Savon::Client
    @credentials  = opts[:credentials] || 
                  ["User", "Pass"]
    @auth_url     = opts[:auth_url] || 
                  "http://search.webofknowledge.com/esti/wokmws/ws/WOKMWSAuthenticate?wsdl"
    @search_url   = opts[:search_url] ||
                  "http://search.webofknowledge.com/esti/wokmws/ws/WokSearch?wsdl"
    @search_xml   = opts[:search_xml] ||     
                  <<-EOF
                  <queryParameters>
                      <databaseId>WOS</databaseId>   
                      <userQuery>CU=chile</userQuery>
                      <editions>
                         <collection>WOS</collection>
                         <edition>SCI</edition>
                      </editions>           
                      <timeSpan>
                         <begin>2000-01-01</begin>
                         <end>2017-12-31</end>
                      </timeSpan>
                      <queryLanguage>en</queryLanguage>
                  </queryParameters>
                  <retrieveParameters>
                      <firstRecord>1</firstRecord>
                      <count>10</count>           
                  </retrieveParameters>
                  EOF
  end

  def authenticate(auth_url=@auth_url, credentials=@credentials)
    @auth_client ||= @client.new(basic_auth: @credentials, wsdl: @auth_url)
    response = @auth_client.call(:authenticate, soap_action: "")
    @session_cookie = response.http.headers["set-cookie"]
  end
  
  def search(query=@search_xml)
    self.authenticate if @session_cookie.nil?
    @search_client ||= @client.new(wsdl: @search_url, headers: {"Cookie"=> @session_cookie})
    @last_search = @search_client.call(:search, soap_action: "", message: query)
  end
  
  def destroy
    @auth_client.call(:close_session, soap_action: "", headers: {"Cookie"=> @session_cookie})
    @session_cookie = nil
    @search_client  = nil
  end  
end

# Savon
soap = SoapWOS.new({
    :credentials => ["USER", "PASS"]
  })

response = soap.search
pp response.to_xml
soap.destroy