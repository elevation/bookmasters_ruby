require 'net/http'
require 'net/https'
require 'uri'

class BookMasters 
  
  cattr_accessor :username, :password
  
  attr_accessor :source, :po, :bkcomments, :stcomments, :sh_amt, :tax
  
  def initialize
    @@username||="guest"
    @@password||="guest"

    @sh_amt = 0
    @tax = 0
  end
  
  def set_ship_address(fname,lname,company,attn,addr1,addr2,city,state,ctry,zip,phone,email)
    @ship_address = 
    {
      :stfname    =>  fname,
      :stlname    =>  lname,
      :stcompany  =>  company,
      :stattn     =>  attn,
      :staddr1    =>  addr1,
      :staddr2    =>  addr2,
      :stcity     =>  city,
      :ststate    =>  state.upcase,
      :stcountry     =>  ctry,
      :stzip      =>  zip,
      :stphone    =>  phone,
      :stemail    =>  email
    }
  end
  
  def set_bill_address(fname,lname,company,attn,addr1,addr2,city,state,ctry,zip,phone,email)
    @bill_address = 
    {
      :btfname    =>  fname,
      :btlname    =>  lname,
      :btcompany  =>  company,
      :btattn     =>  attn,
      :btaddr1    =>  addr1,
      :btaddr2    =>  addr2,
      :btcity     =>  city,
      :btstate    =>  state.upcase,
      :btcountry  =>  ctry,
      :btzip      =>  zip,
      :btphone    =>  phone,
      :btemail    =>  email
    }
  end
  
  # sets the cc fields
  def set_cc(ccno, exp, vin, type) 
    @cc = 
    {
      :ccno     => ccno.gsub("-",""),
      :expdate  => exp,
      :vin      => vin,
      :mop      => type
    }
  end
  
  def build_order(orno=nil,ppo=nil,ship_mthd=nil) 
    
    @orno = orno || Time.now.strftime('%m-%d-%y-%H:%M:%S')
    @ppo = ppo ||= "Web Services v1.2"
    @ship_mthd = ship_mthd
    
    data = 
    {
      # basic order fields
      :action   => "neworder",
      :or_no    =>  @orno,
      :username =>  @@username,
      :password =>  @@password,
      
      # Additional Order Information
      :source     =>  @source,
      :ppo        =>  @ppo,
      :sh_amt     =>  sprintf("%.2f", @sh_amt ),
      :tax        =>  sprintf("%.2f", @tax),
      :comments =>  @bkcomments,
      :stcomments =>  @stcomments,
      :ship_method  =>  @ship_mthd
    }
    
    # merge in the ship_address fields if defined
    data.merge!(@ship_address) if @ship_address
    
    # merge in the bill_address fields if defined
    data.merge!(@bill_address) if @bill_address
    
    # merge in the credit card fields if defined
    data.merge!(@cc) if @cc
   
    @sid = send_request(data)

  end
  
  def add_product(pmid,qty,discount=0,uprice=nil) 
    return false if pmid.blank? || qty.blank?

    data = 
    {
      :action   => "addtoorder",
      :sid      => @sid,
      :qty      => qty,
      :pmid     => pmid,
      :discount => sprintf("%.2f",discount)
    }
    
    data[:uprice] = sprintf("%.2f", uprice) if uprice

    # send the request
    send_request(data)
  end
  
  def finish 
    data = { :action => "finish", :sid => @sid }
    send_request(data)
  end
  
  private 
  
  # opens an ssl connection to bookmasters and returns the body of the result   
  def send_request(data={}) 
    puts "BOOKMASTERS REQUEST: #{data.inspect}"
    url = URI.parse('https://stats.bookmasters.com/services/order/index.php')
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data(data)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    res = http.start {|http| http.request(req) }
    puts "BOOKMASTERS RESPONSE: #{res.body.strip}"
    return res.body.strip
  end

end

