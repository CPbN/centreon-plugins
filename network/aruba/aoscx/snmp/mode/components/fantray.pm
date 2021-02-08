#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::aruba::aoscx::snmp::mode::components::fantray;

use strict;
use warnings;

my $mapping = {
    name  => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.11.4.1.1.3' }, # arubaWiredFanTrayName
    state => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.11.4.1.1.4' }  # arubaWiredFanTrayState
};
my $oid_arubaWiredFanTrayEntry = '.1.3.6.1.4.1.47196.4.1.1.3.11.4.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_arubaWiredFanTrayEntry,
        start => $mapping->{name}->{oid},
        end => $mapping->{state}->{oid}
    };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking fan trays');
    $self->{components}->{fantray} = { name => 'fantray', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fantray'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_arubaWiredFanTrayEntry}})) {
        next if ($oid !~ /^$mapping->{state}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_arubaWiredFanTrayEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fantray', instance => $instance, name => $result->{name}));
        $self->{components}->{fantray}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan tray '%s' status is %s [instance: %s]",
                $result->{name},
                $result->{state},
                $instance
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'fantray', value => $result->{state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fan tray '%s' status is %s",
                    $result->{name}, $result->{state}
                )
            );
        }
    }
}

1;
