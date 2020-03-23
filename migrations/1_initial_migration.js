const Migrations = artifacts.require("Migrations");
const ticketingStystem = artifacts.require("ticketingSystem");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.link(Migrations, ticketingStystem);
  deployer.deploy(ticketingStystem);
};
