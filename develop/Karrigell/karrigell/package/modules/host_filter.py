def main(handler):
    """ conf_filter() must return a host name like localhost, www.mydomain.com:8080...
    host input syntax is 'domainname' or 'domainname:port'
    With this function, you can filter port and domain/subdomain names.
    
    An example filtering host is :
    if host in hosts :
        return host
    else :
        raise HTTP_REDIRECTION, "http://www.dummy.com"
        
    A more complex and usefull filtering is :
    if host in hosts :
        return host
    else :
        h = '.'.join(host.split('.')[-2:])
        for k,v in hosts.iteritems():
            if h == '.'.join(k.split('.')[-2:]):
                raise HTTP_REDIRECTION, "http://" + k
        raise HTTP_REDIRECTION, "http://www.dummy.com"    # Redirection should be set according to configuration
    return host
    
    Most simple example : 
    return host    # No filtering : output = input
    """
    import k_config
    if not handler.host.split(":")[0] in k_config.config:
        handler.config = k_config.config[None]
        raise handler.ns["HTTP_REDIRECTION"],"http://localhost"
        