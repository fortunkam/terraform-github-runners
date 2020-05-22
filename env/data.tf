data "http" "httpbin" {
  url = "http://httpbin.org/ip"

  request_headers = {
    Accept = "application/json"
  }
}