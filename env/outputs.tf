output "bastion_password" {
  value = random_password.windows_runner_password.result
}


output "private_key_pem" {
  value = tls_private_key.linux_runner.private_key_pem
}